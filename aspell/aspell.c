#include <Shlwapi.h>
#include <Windows.h>
#include <fcntl.h>
#include <io.h>
#include <stdio.h>
#include <tchar.h>

static HANDLE
duplicate(HANDLE handle)
{
    HANDLE duplicatedHandle = INVALID_HANDLE_VALUE;

    if (handle == INVALID_HANDLE_VALUE)
        return handle;

    if (DuplicateHandle(
            GetCurrentProcess(), /* Source process handle */
            handle,              /* Source handle to duplicate */
            GetCurrentProcess(), /* Target process handle */
            &duplicatedHandle,   /* Pointer to the duplicated handle */
            0,                   /* Desired access rights (0 for same access) */
            TRUE, /* Inheritable flag (FALSE for non-inheritable) */
            DUPLICATE_SAME_ACCESS /* Options */
                       ))
        return duplicatedHandle;
    else {
        fprintf(stderr, "Error creating duplicate handle. Error code: %lu\n",
                GetLastError());
        exit(1);
    }
    return duplicatedHandle;
}

static const TCHAR *
aspellInstallPathFromRegistry()
{
    static const TCHAR keyPath[] = TEXT("SOFTWARE\\Aspell");
    DWORD              dwType    = REG_SZ;
    HKEY               hKey;
    LPTSTR             path;
    DWORD              length;

    LSTATUS result;

    result =
        RegOpenKeyEx(HKEY_LOCAL_MACHINE, keyPath, 0, KEY_QUERY_VALUE, &hKey);
    if (result != ERROR_SUCCESS) {
        fprintf(stderr, "RegOpenKeyEx failed: %ld\n", GetLastError());
        return NULL;
    }

    result = RegQueryValueEx(hKey, NULL, NULL, &dwType, NULL, &length);
    if (result == ERROR_SUCCESS) {
        path = (LPTSTR)LocalAlloc(0, length * sizeof(path[0]));
        if (path == NULL) {
            fprintf(stderr, "LocalAlloc failed: %ld\n", GetLastError());
            RegCloseKey(hKey);
            return NULL;
        }

        result =
            RegQueryValueEx(hKey, NULL, NULL, &dwType, (LPBYTE)path, &length);
        if (result != ERROR_SUCCESS) {
            printf("RegQueryValueEx failed: %ld\n", GetLastError());
            RegCloseKey(hKey);
            return NULL;
        }
    } else if (result == ERROR_MORE_DATA)
        fprintf(stderr, "Buffer too small\n");
    else
        fprintf(stderr, "RegQueryValueEx failed: %ld\n", GetLastError());

    RegCloseKey(hKey);

    return path;
}

int
main()
{
    _setmode(_fileno(stdout), _O_WTEXT);

    const TCHAR *aspellInstallPath = aspellInstallPathFromRegistry();
    if (!aspellInstallPath)
        return 1;

    TCHAR userProfile[MAX_PATH];
    DWORD userProfileSize =
        GetEnvironmentVariable(TEXT("USERPROFILE"), userProfile, MAX_PATH);

    if (userProfileSize == 0) {
        fprintf(stderr, "Error reading USERPROFILE environment variable.\n");
        return 1;
    } else {
        /* Replace backslashes with forward slashes */
        for (DWORD i = 0; i < userProfileSize; ++i)
            if (userProfile[i] == '\\')
                userProfile[i] = '/';

        if (!SetEnvironmentVariable(TEXT("HOME"), userProfile)) {
            fprintf(stderr, "Error setting HOME environment variable.\n");
            return 1;
        }
    }

    TCHAR aspellExecutablePath[MAX_PATH];
    if (!PathCombine(aspellExecutablePath, aspellInstallPath,
                     TEXT("bin\\aspell.exe")))
        fprintf(stderr, "error constructing aspell.exe executable path.\n");

    /* get arguments after program name */
    LPTSTR commandLine = GetCommandLine();

    /* Start a subprocess (cmd.exe in this case) */
    STARTUPINFO         si;
    PROCESS_INFORMATION pi;

    ZeroMemory(&si, sizeof(STARTUPINFO));
    si.cb = sizeof(STARTUPINFO);

    si.dwFlags     = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;

    si.hStdInput  = duplicate(GetStdHandle(STD_INPUT_HANDLE));
    si.hStdOutput = duplicate(GetStdHandle(STD_OUTPUT_HANDLE));
    si.hStdError  = duplicate(GetStdHandle(STD_ERROR_HANDLE));
    si.dwFlags   |= STARTF_USESTDHANDLES;

    ZeroMemory(&pi, sizeof(PROCESS_INFORMATION));

    if (!CreateProcess(aspellExecutablePath, commandLine,
                       NULL, /* Process handle not inheritable */
                       NULL, /* Thread handle not inheritable */
                       TRUE, /* Set handle inheritance to TRUE */
                       0,    /* No creation flags */
                       NULL, /* Use parent's environment block */
                       NULL, /* Use parent's starting directory */
                       &si,  /* Pointer to STARTUPINFO structure */
                       &pi   /* Pointer to PROCESS_INFORMATION structure */
                      ))
    {
        fprintf(stderr, "Error creating subprocess. Error code: %ld\n",
                GetLastError());
        return 1;
    }

    /* Wait for the subprocess to exit */
    WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);

    /* Close process and thread handles */
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return exitCode;
}
