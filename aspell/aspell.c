#include <Windows.h>
#include <Shlwapi.h>
#include <io.h>
#include <fcntl.h>
#include <tchar.h>
#include <stdio.h>

#define PROGRAM_FILES TEXT("C:\\Program Files")
#define ASPELL_PATH   TEXT("Aspell\\bin\\aspell.exe")

static HANDLE
duplicate(HANDLE handle)
{
    HANDLE duplicatedHandle = INVALID_HANDLE_VALUE;

    if (handle == INVALID_HANDLE_VALUE)
        return handle;

    if (DuplicateHandle(
            GetCurrentProcess(),    /* Source process handle */
            handle,                 /* Source handle to duplicate */
            GetCurrentProcess(),    /* Target process handle */
            &duplicatedHandle,      /* Pointer to the duplicated handle */
            0,                      /* Desired access rights (0 for same access) */
            TRUE,                   /* Inheritable flag (FALSE for non-inheritable) */
            DUPLICATE_SAME_ACCESS   /* Options */
                       ))
        return duplicatedHandle;
    else {
        fprintf(stderr, "Error creating duplicate handle. Error code: %lu\n", GetLastError());
        exit(1);
    }
    return duplicatedHandle;
}

int
main()
{
    _setmode(_fileno(stdout), _O_WTEXT);

    TCHAR programFiles[MAX_PATH];
    DWORD programFilesSize = GetEnvironmentVariable(TEXT("ProgramFiles(x86)"),
                                                    programFiles,
                                                    MAX_PATH);
    if (programFilesSize == 0)
        programFilesSize = GetEnvironmentVariable(TEXT("ProgramFiles"),
                                                  programFiles,
                                                  MAX_PATH);

    if (programFilesSize == 0)
        memcpy(programFiles, PROGRAM_FILES, sizeof(PROGRAM_FILES) / sizeof(programFiles[0]));

    TCHAR userProfile[MAX_PATH];
    DWORD userProfileSize = GetEnvironmentVariable(TEXT("USERPROFILE"),
                                                   userProfile,
                                                   MAX_PATH);

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
    if (!PathCombine(aspellExecutablePath, programFiles, ASPELL_PATH))
        fprintf(stderr, "error constructin aspell.exe executable path.\n");

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

    if (!CreateProcess(
            aspellExecutablePath,
            commandLine,
            NULL,   /* Process handle not inheritable */
            NULL,   /* Thread handle not inheritable */
            TRUE,   /* Set handle inheritance to TRUE */
            0,      /* No creation flags */
            NULL,   /* Use parent's environment block */
            NULL,   /* Use parent's starting directory */
            &si,    /* Pointer to STARTUPINFO structure */
            &pi     /* Pointer to PROCESS_INFORMATION structure */
                      ))
    {
        fprintf(stderr, "Error creating subprocess. Error code: %ld\n", GetLastError());
        return 1;
    }

    /* Wait for the subprocess to exit */
    WaitForSingleObject(pi.hProcess, INFINITE);

    /* Close process and thread handles */
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return 0;
}
