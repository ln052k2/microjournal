#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>

int main(int argc, char *argv[]) {
    // Get home directory
    const char *home_dir = getenv("HOME");
    if (!home_dir) {
        struct passwd *pw = getpwuid(getuid());
        home_dir = pw->pw_dir;
    }

    // Build full path to ~/documents/journal.txt
    char filepath[512];
    snprintf(filepath, sizeof(filepath), "%s/documents/journal.txt", home_dir);

    // Open journal file for appending
    FILE *file = fopen(filepath, "a");
    if (!file) {
        perror("Error opening journal file");
        return 1;
    }

    // Get current date and time
    time_t now = time(NULL);
    char time_str[128];
    strftime(time_str, sizeof(time_str), "\n=== %Y-%m-%d %H:%M:%S ===\n", localtime(&now));

    // Write timestamp
    fputs(time_str, file);

    // If quick mode and message provided
    if (argc >= 3 && strcmp(argv[1], "-q") == 0) {
        fputs(argv[2], file);
        fputc('\n', file);
        fclose(file);
        return 0;
    }

    // Close file and open nano
    fclose(file);
    
    char command[600];
    snprintf(command, sizeof(command), "nano %s", filepath);
    system(command);

    return 0;
}
