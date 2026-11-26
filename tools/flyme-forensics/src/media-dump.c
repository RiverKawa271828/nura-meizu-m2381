/* media-dump.c — minimal media-ctl -p equivalent (static, forensic)
 * usage: media-dump /dev/mediaN   (prints device info + entities + pads + links)
 */
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/media.h>

int main(int argc, char **argv)
{
	if (argc < 2) { fprintf(stderr, "usage: %s /dev/mediaN\n", argv[0]); return 2; }
	int fd = open(argv[1], O_RDWR);
	if (fd < 0) { perror(argv[1]); return 1; }

	struct media_device_info mdi;
	if (ioctl(fd, MEDIA_IOC_DEVICE_INFO, &mdi) < 0) { perror("MEDIA_IOC_DEVICE_INFO"); return 1; }
	printf("== %s driver=%s model=%s bus=%s hw_rev=%u ==\n", argv[1],
	       mdi.driver, mdi.model, mdi.bus_info, mdi.hw_revision);

	/* enumerate entities: id=0 first, then last returned id; EINVAL ends */
	unsigned prev = 0;
	for (;;) {
		struct media_entity_desc ent;
		memset(&ent, 0, sizeof(ent));
		ent.id = prev ? prev : 0;
		if (ioctl(fd, MEDIA_IOC_ENUM_ENTITIES, &ent) < 0)
			break; /* done (EINVAL) */
		prev = ent.id;

		printf("- entity %u: %s (pads %u links %u)\n", ent.id, ent.name,
		       ent.pads, ent.links);
		if (ent.type & MEDIA_ENT_FL_DEFAULT)
			printf("  (default)\n");

		if (ent.pads == 0 && ent.links == 0)
			continue;

		struct media_pad_desc *pads = calloc(ent.pads ? ent.pads : 1, sizeof(*pads));
		struct media_link_desc *links = calloc(ent.links ? ent.links : 1, sizeof(*links));
		struct media_links_enum le;
		memset(&le, 0, sizeof(le));
		le.entity = ent.id;
		le.pads = pads;
		le.links = links;
		if (ioctl(fd, MEDIA_IOC_ENUM_LINKS, &le) == 0) {
			for (unsigned i = 0; i < ent.pads; i++)
				printf("  pad%u: %s flags=0x%08x\n", pads[i].index,
				       pads[i].flags & MEDIA_PAD_FL_SINK ? "SINK" :
				       pads[i].flags & MEDIA_PAD_FL_SOURCE ? "SOURCE" : "?",
				       pads[i].flags);
			for (unsigned i = 0; i < ent.links; i++)
				printf("  link [%u.%u] -> [%u.%u] flags=0x%08x %s\n",
				       links[i].source.entity, links[i].source.index,
				       links[i].sink.entity, links[i].sink.index,
				       links[i].flags,
				       links[i].flags & MEDIA_LNK_FL_ENABLED ? "ENABLED" : "");
		}
		free(pads);
		free(links);
	}
	close(fd);
	return 0;
}
