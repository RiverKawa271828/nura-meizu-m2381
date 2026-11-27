/* i2c-scan.c — minimal i2cdetect equivalent (static, forensic)
 * usage: i2c-scan [bus-range]   (scans /dev/i2c-0..N, prints address maps for live buses)
 * read-byte detection; only reports, never writes.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

int scan_bus(int n, char *out, size_t outsz)
{
	char path[32];
	snprintf(path, sizeof(path), "/dev/i2c-%d", n);
	int fd = open(path, O_RDWR);
	if (fd < 0) return 0;

	size_t o = 0;
	o += snprintf(out + o, outsz - o, "i2c-%d:", n);
	int found = 0;
	for (unsigned addr = 0x03; addr <= 0x77; addr++) {
		if (ioctl(fd, I2C_SLAVE, addr) < 0) continue;
		unsigned char b;
		if (read(fd, &b, 1) >= 0) {
			o += snprintf(out + o, outsz - o, " %02x", addr);
			found++;
		}
	}
	o += snprintf(out + o, outsz - o, found ? "  (%d)\n" : " (empty)\n", found);
	close(fd);
	return found;
}

int main(int argc, char **argv)
{
	int maxbus = argc > 1 ? atoi(argv[1]) : 24;
	char line[512];
	int total = 0;
	for (int n = 0; n < maxbus; n++) {
		line[0] = 0;
		if (scan_bus(n, line, sizeof(line))) {
			fputs(line, stdout);
			total++;
		}
	}
	printf("buses with devices: %d\n", total);
	return 0;
}
