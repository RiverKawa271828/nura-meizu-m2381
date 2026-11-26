/* tiny-mix.c — minimal ALSA control dumper (static, forensic; tinymix subset)
 * usage: tiny-mix /dev/snd/controlCN   (dumps every control: numid/name/iface/type/values)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sound/asound.h>

static const char *ifname(snd_ctl_elem_iface_t i)
{
	switch (i) {
	case SNDRV_CTL_ELEM_IFACE_CARD: return "card";
	case SNDRV_CTL_ELEM_IFACE_HWDEP: return "hwdep";
	case SNDRV_CTL_ELEM_IFACE_MIXER: return "mixer";
	case SNDRV_CTL_ELEM_IFACE_PCM: return "pcm";
	case SNDRV_CTL_ELEM_IFACE_RAWMIDI: return "rawmidi";
	case SNDRV_CTL_ELEM_IFACE_TIMER: return "timer";
	case SNDRV_CTL_ELEM_IFACE_SEQUENCER: return "sequencer";
	default: return "?";
	}
}

static const char *typename(snd_ctl_elem_type_t t)
{
	switch (t) {
	case SNDRV_CTL_ELEM_TYPE_BOOLEAN: return "bool";
	case SNDRV_CTL_ELEM_TYPE_INTEGER: return "int";
	case SNDRV_CTL_ELEM_TYPE_ENUMERATED: return "enum";
	case SNDRV_CTL_ELEM_TYPE_BYTES: return "bytes";
	case SNDRV_CTL_ELEM_TYPE_IEC958: return "iec958";
	case SNDRV_CTL_ELEM_TYPE_INTEGER64: return "int64";
	default: return "?";
	}
}

int main(int argc, char **argv)
{
	if (argc < 2) { fprintf(stderr, "usage: %s /dev/snd/controlCN\n", argv[0]); return 2; }
	int fd = open(argv[1], O_RDWR);
	if (fd < 0) fd = open(argv[1], O_RDONLY);
	if (fd < 0) { perror(argv[1]); return 1; }

	struct snd_ctl_card_info cinfo;
	memset(&cinfo, 0, sizeof(cinfo));
	if (ioctl(fd, SNDRV_CTL_IOCTL_CARD_INFO, &cinfo) == 0)
		printf("== %s card=%d driver=%s name=%s ==\n", argv[1],
		       cinfo.card, cinfo.driver, cinfo.name);

	/* total element count */
	struct snd_ctl_elem_list lst;
	memset(&lst, 0, sizeof(lst));
	if (ioctl(fd, SNDRV_CTL_IOCTL_ELEM_LIST, &lst) < 0) { perror("ELEM_LIST"); return 1; }
	unsigned total = lst.count;
	printf("controls: %u\n", total);

	unsigned chunk = total < 4096 ? total : 4096;
	struct snd_ctl_elem_id *ids = calloc(chunk, sizeof(*ids));

	for (unsigned base = 0; base < total; base += chunk) {
		unsigned n = total - base < chunk ? total - base : chunk;
		memset(&lst, 0, sizeof(lst));
		lst.offset = base;
		lst.space = n;
		lst.used = 0;
		lst.pids = ids;
		if (ioctl(fd, SNDRV_CTL_IOCTL_ELEM_LIST, &lst) < 0) { perror("ELEM_LIST"); break; }

		for (unsigned i = 0; i < lst.used; i++) {
			struct snd_ctl_elem_info info;
			memset(&info, 0, sizeof(info));
			info.id = ids[i];
			if (ioctl(fd, SNDRV_CTL_IOCTL_ELEM_INFO, &info) < 0) {
				printf("numid=%u <ELEM_INFO failed>\n", ids[i].numid);
				continue;
			}
			printf("numid=%u iface=%s name='%s' type=%s count=%u",
			       info.id.numid, ifname(info.id.iface), info.id.name,
			       typename(info.type), info.count);
			if (info.type == SNDRV_CTL_ELEM_TYPE_INTEGER ||
			    info.type == SNDRV_CTL_ELEM_TYPE_INTEGER64) {
				if (info.type == SNDRV_CTL_ELEM_TYPE_INTEGER)
					printf(" range=[%ld..%ld]",
					       info.value.integer.min,
					       info.value.integer.max);
				else
					printf(" range=[%lld..%lld]",
					       info.value.integer64.min,
					       info.value.integer64.max);
			}
			printf("\n");

			/* best-effort current values (read-only elements etc. skip) */
			struct snd_ctl_elem_value val;
			memset(&val, 0, sizeof(val));
			val.id = info.id;
			if (ioctl(fd, SNDRV_CTL_IOCTL_ELEM_READ, &val) == 0) {
				printf("  values:");
				unsigned cnt = info.count > 12 ? 12 : info.count;
				for (unsigned k = 0; k < cnt; k++) {
					switch (info.type) {
					case SNDRV_CTL_ELEM_TYPE_BOOLEAN:
					case SNDRV_CTL_ELEM_TYPE_INTEGER:
						printf(" %ld", val.value.integer.value[k]); break;
					case SNDRV_CTL_ELEM_TYPE_INTEGER64:
						printf(" %lld", val.value.integer64.value[k]); break;
					case SNDRV_CTL_ELEM_TYPE_ENUMERATED: {
						struct snd_ctl_elem_info e2 = info;
						e2.value.enumerated.item = val.value.enumerated.item[k];
						if (ioctl(fd, SNDRV_CTL_IOCTL_ELEM_INFO, &e2) == 0)
							printf(" [%u]'%s'", val.value.enumerated.item[k],
							       e2.value.enumerated.name);
						else
							printf(" [%u]", val.value.enumerated.item[k]);
						break;
					}
					default:
						printf(" %02x", val.value.bytes.data[k]); break;
					}
				}
				if (info.count > 12) printf(" ...(%u)", info.count);
				printf("\n");
			}
		}
	}
	close(fd);
	return 0;
}
