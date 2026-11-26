/* v4l-fmt.c — minimal v4l2 device format dumper (static, forensic)
 * usage: v4l-fmt /dev/videoN   (QUERYCAP + G_FMT capture mplane/single + ENUM_FMT count)
 */
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>

static void pfourcc(unsigned f, char *out)
{
	out[0] = f & 0xff; out[1] = (f >> 8) & 0xff;
	out[2] = (f >> 16) & 0xff; out[3] = (f >> 24) & 0xff; out[4] = 0;
}

int main(int argc, char **argv)
{
	if (argc < 2) { fprintf(stderr, "usage: %s /dev/videoN\n", argv[0]); return 2; }
	int fd = open(argv[1], O_RDWR);
	if (fd < 0) { perror(argv[1]); return 1; }

	struct v4l2_capability cap;
	if (ioctl(fd, VIDIOC_QUERYCAP, &cap) == 0)
		printf("== %s driver=%s card=%s caps=0x%08x ==\n", argv[1],
		       cap.driver, cap.card, cap.device_caps);

	/* capture format: mplane first, fall back to single plane */
	struct v4l2_format fmt;
	memset(&fmt, 0, sizeof(fmt));
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
	if (ioctl(fd, VIDIOC_G_FMT, &fmt) == 0) {
		char f[5]; pfourcc(fmt.fmt.pix_mp.pixelformat, f);
		printf("capture(mplane): %c%c%c%c %ux%u planes=%u bpl=%u imgsize=%u\n",
		       f[0], f[1], f[2], f[3], fmt.fmt.pix_mp.width,
		       fmt.fmt.pix_mp.height, fmt.fmt.pix_mp.num_planes,
		       fmt.fmt.pix_mp.plane_fmt[0].bytesperline,
		       fmt.fmt.pix_mp.plane_fmt[0].sizeimage);
	} else {
		memset(&fmt, 0, sizeof(fmt));
		fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		if (ioctl(fd, VIDIOC_G_FMT, &fmt) == 0) {
			char f[5]; pfourcc(fmt.fmt.pix.pixelformat, f);
			printf("capture(single): %c%c%c%c %ux%u bpl=%u imgsize=%u\n",
			       f[0], f[1], f[2], f[3], fmt.fmt.pix.width,
			       fmt.fmt.pix.height, fmt.fmt.pix.bytesperline,
			       fmt.fmt.pix.sizeimage);
		} else {
			perror("VIDIOC_G_FMT");
		}
	}

	/* enumerate supported capture formats (first 32) */
	memset(&fmt, 0, sizeof(fmt));
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
	fmt.fmt.pix_mp.plane_fmt[0].sizeimage = 0; /* unused for enum */
	for (unsigned i = 0, shown = 0; i < 64 && shown < 32; i++) {
		struct v4l2_fmtdesc d;
		memset(&d, 0, sizeof(d));
		d.index = i;
		d.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
		if (ioctl(fd, VIDIOC_ENUM_FMT, &d) < 0) break;
		char f[5]; pfourcc(d.pixelformat, f);
		printf("enum[%u]: '%s' (%s)\n", i, f, d.description);
		shown++;
	}
	close(fd);
	return 0;
}
