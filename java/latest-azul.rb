#!/usr/bin/env ruby
# frozen_string_literal: true

# latest-azul.rb — fetch and download latest Azul Zulu JDK/JRE packages
# Linux port of latest-azul.ps1

require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'digest'
require 'optparse'

# ---------------------------------------------------------------------------
# Download profiles
# Each top-level key is a profile name; prefix with '#' to disable it.
# ---------------------------------------------------------------------------
PACKAGES = {
  "windows" => {
    8  => {
      operating_systems: %w[windows],
      architectures:     %w[x86 amd64],
      package_types:     %w[jre jdk],
      archive_types:     %w[msi zip],
    },
    11 => {
      operating_systems: %w[windows],
      architectures:     %w[amd64],
      package_types:     %w[jdk],
      archive_types:     %w[msi zip],
    },
    17 => {
      operating_systems: %w[windows],
      architectures:     %w[x86 amd64],
      package_types:     %w[jre jdk],
      archive_types:     %w[msi zip],
    },
    21 => {
      operating_systems: %w[windows],
      architectures:     %w[amd64],
      package_types:     %w[jdk],
      archive_types:     %w[msi zip],
    },
    25 => {
      operating_systems: %w[windows],
      architectures:     %w[amd64],
      package_types:     %w[jdk],
      archive_types:     %w[msi zip],
    },
  },

  "linux" => {
    8  => {
      operating_systems: %w[linux-glibc],
      architectures:     %w[x86 amd64 aarch64],
      package_types:     %w[jdk],
      archive_types:     %w[deb tar.gz],
      prefix:            "linux/",
    },
    21 => {
      operating_systems: %w[linux-glibc],
      architectures:     %w[amd64 aarch64],
      package_types:     %w[jdk],
      archive_types:     %w[deb tar.gz],
      prefix:            "linux/",
    },
    25 => {
      operating_systems: %w[linux-glibc],
      architectures:     %w[amd64 aarch64],
      package_types:     %w[jdk],
      archive_types:     %w[deb tar.gz],
      prefix:            "linux/",
    },
  },
}.freeze

# ---------------------------------------------------------------------------
# Azul arch normalisation  (arch + "_" + hw_bitness → friendly name)
# ---------------------------------------------------------------------------
AZUL_ARCH = {
  "x86_32"  => "x86",
  "x86_64"  => "amd64",
  "arm_32"  => "aarch32",
  "arm_64"  => "aarch64",
  "mips_32" => "mips",
  "mips_64" => "mips64",
  "ppc_32"  => "ppc",
  "ppc_64"  => "ppc64",
}.freeze

def to_named_arch(arch, hw_bitness)
  AZUL_ARCH.fetch("#{arch}_#{hw_bitness}", "#{arch}-#{hw_bitness}")
end

# ---------------------------------------------------------------------------
# Azul metadata API query
# ---------------------------------------------------------------------------
API_URL = "https://api.azul.com/metadata/v1/zulu/packages/"

def azul_metadata(java_major)
  params = URI.encode_www_form(
    "availability_types" => "ca",
    "product"            => "zulu",
    "java_version"       => java_major,
    "release_type"       => "PSU",
    "latest"             => "true",
    "crac_supported"     => "false",
    "page_size"          => "1000",
    "include_fields"     => "os,lib_c_type,arch,hw_bitness,java_package_type," \
                            "archive_type,javafx_bundled,sha256_hash"
  )
  uri = URI("#{API_URL}?#{params}")

  warn "  querying #{uri}"
  response = Net::HTTP.get_response(uri)

  unless response.is_a?(Net::HTTPSuccess)
    raise "metadata HTTP #{response.code}: #{response.message}"
  end

  JSON.parse(response.body)
end

# ---------------------------------------------------------------------------
# Filter, deduplicate, and format one profile+version combination
# Returns an array of "url#dest_folder/filename" strings
# ---------------------------------------------------------------------------
def zulu_filter(metadata, config)
  os_filter   = config[:operating_systems] || []
  arch_filter = config[:architectures]     || []
  pkg_filter  = config[:package_types]     || []
  arc_filter  = config[:archive_types]     || []
  prefix      = config[:prefix]            || ""

  # --- apply inclusion filters ---
  filtered = metadata.select do |pkg|
    # skip if explicitly marked not-latest
    next false if pkg["latest"] == false

    os   = pkg["lib_c_type"] ? "#{pkg["os"]}-#{pkg["lib_c_type"]}" : pkg["os"]
    arch = to_named_arch(pkg["arch"], pkg["hw_bitness"])

    os_filter.include?(os)          &&
      arch_filter.include?(arch)    &&
      pkg_filter.include?(pkg["java_package_type"]) &&
      arc_filter.include?(pkg["archive_type"])
  end

  # --- keep only the highest Zulu release per logical slot ---
  # group key mirrors the PS Group-Object expression
  groups = filtered.group_by do |pkg|
    [
      pkg["os"],
      pkg["arch"],
      pkg["hw_bitness"],
      pkg["java_package_type"],
      Array(pkg["java_version"]).first,
      pkg["javafx_bundled"],
      pkg["archive_type"],
    ]
  end

  latest = groups.map do |_key, group|
    group.max_by { |pkg| Array(pkg["zulu_version"]) }
  end

  # --- format as "url#folder/filename" ---
  latest.map do |pkg|
    name         = pkg["name"].to_s
    package_type = pkg["java_package_type"].downcase
    arch         = to_named_arch(pkg["arch"], pkg["hw_bitness"])
    major        = Array(pkg["java_version"]).first

    folder = "#{prefix}#{package_type}#{major}"
    folder = "#{folder}/#{arch}" unless arch == "amd64"

    "#{pkg["download_url"]}##{folder}/#{name}"
  end
end

# ---------------------------------------------------------------------------
# HTTP download with redirect following and optional SHA-256 verification
# ---------------------------------------------------------------------------
def download_file(url, dest, expected_sha256: nil, verbose: false)
  uri = URI(url)

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    request  = Net::HTTP::Get.new(uri)
    http.request(request) do |response|
      case response
      when Net::HTTPRedirection
        return download_file(response["location"], dest,
                             expected_sha256: expected_sha256, verbose: verbose)
      when Net::HTTPSuccess
        FileUtils.mkdir_p(File.dirname(dest))
        digest = Digest::SHA256.new
        File.open(dest, "wb") do |f|
          response.read_body do |chunk|
            f.write(chunk)
            digest.update(chunk)
          end
        end
        if expected_sha256
          actual = digest.hexdigest
          unless actual == expected_sha256
            File.delete(dest)
            raise "SHA-256 mismatch for #{File.basename(dest)}:\n" \
                  "  expected #{expected_sha256}\n  got      #{actual}"
          end
          warn "    SHA-256 OK" if verbose
        end
      else
        raise "download HTTP #{response.code}: #{response.message} — #{url}"
      end
    end
  end
end

# ---------------------------------------------------------------------------
# CLI options
# ---------------------------------------------------------------------------
options = { project_name: "java-azul", dry_run: false, verbose: false }

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"
  opts.on("-n", "--dry-run",        "Print URLs without downloading")        { options[:dry_run]  = true }
  opts.on("-v", "--verbose",        "Verbose output")                        { options[:verbose]  = true }
  opts.on("-o DIR", "--output DIR", "Output base directory (default: ./<project-name>)") { |d| options[:output] = d }
  opts.on("-p NAME", "--project NAME", "Project name subfolder (default: java-azul)")     { |n| options[:project_name] = n }
  opts.on("-h", "--help",           "Show this help")                        { puts opts; exit }
end.parse!

output_dir = options[:output] || options[:project_name]

# ---------------------------------------------------------------------------
# Main: iterate profiles → java versions → query → filter → collect
# ---------------------------------------------------------------------------
candidates = []

PACKAGES.keys.sort.reverse.each do |profile|
  if profile.start_with?("#")
    warn "skipping disabled profile: #{profile}"
    next
  end

  warn "profile: #{profile}"

  PACKAGES[profile].keys.sort.each do |java_major|
    warn "  java #{java_major}:"
    begin
      metadata = azul_metadata(java_major)
      if metadata.empty?
        warn "  no metadata returned for java #{java_major}"
        next
      end
      results = zulu_filter(metadata, PACKAGES[profile][java_major])
      warn "  #{results.size} candidate(s)"
      candidates.concat(results)
    rescue StandardError => e
      warn "  ERROR: #{e.message}"
    end
  end
end

if candidates.empty?
  warn "no download candidates found"
  exit 1
end

# ---------------------------------------------------------------------------
# Download (or print in dry-run mode)
# ---------------------------------------------------------------------------
candidates.sort.each do |entry|
  url, dest_rel = entry.split("#", 2)
  dest = File.join(output_dir, dest_rel)

  if options[:dry_run]
    puts "#{url}  →  #{dest}"
    next
  end

  if File.exist?(dest)
    warn "exists, skipping: #{dest}"
    next
  end

  warn "downloading → #{dest}"
  begin
    download_file(url, dest, verbose: options[:verbose])
  rescue StandardError => e
    warn "FAILED: #{e.message}"
  end
end
