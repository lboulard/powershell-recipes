
URL

  - https://www.azul.com
  - https://www.azul.com/downloads/?package=#zulu

  - https://endoflife.date/azul-zulu

Azul web API

  - https://api.azul.com/metadata/v1/zulu/packages/
  - https://docs.azul.com/core/metadata-api-migration#request-filter-differences

  Query:
    availability_types          ca
    java_version                8, 11, 17, 21
    os                          windows, macosx, linux_glibc, linux_musl
    arch                        i686, x64, aarch64
    archive_type                msi, cab, dmg, zip, tar.gz, deb, rpm
    package_type                jre, jdk
    javafx_bundled              false, true
    crac_supported              false
    latest                      true
    include_fields              sha256_hash
    page_size                   1

  Query (MS Windows):
    os                          windows
    arch                        i686, x64, aarch64 (java_version >= 17)
    archive_type                msi, cab, zip

  Query (Linux):
    os                          linux_glibc
    arch                        i686, x64, aarch64, ppc64 (java_version == 8)
    archive_type                zip, tar.gz, deb, rpm

  Query (Alpine Linux):
    os                          linux_musl
    arch                        x64, aarch64
    archive_type                tar.gz

  Query (MacOS):
    os                          macosx
    arch                        x64, aarch64
    archive_type                dmg, zip, tar.gz

  Latest JRE/JDK downloads (not LTS)
  - https://api.azul.com/metadata/v1/zulu/packages/?availability_types=ca
