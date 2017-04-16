fix-mod_devicetable.patch
=========================

Fix a gcc61 issue (according to https://github.com/manjaro/packages-core/issues/40 )

In file included from drivers/hid/hid-hyperv.c:16:0:
include/linux/module.h:138:40: error: storage size of ‘__mod_vmbus__id_table_device_table’ isn’t known
   extern const struct type##_device_id __mod_##type##__##name##_device_table \
                                        ^
drivers/hid/hid-hyperv.c:588:1: note: in expansion of macro ‘MODULE_DEVICE_TABLE’
 MODULE_DEVICE_TABLE(vmbus, id_table);
 ^~~~~~~~~~~~~~~~~~~


aufs316-3.16.7.4.patch(z)
=======================

not applied, there's a patch in aufs_sources

 error: ‘struct dentry’ has no member named ‘d_alias’
 error: ‘union <anonymous>’ has no member named ‘d_child’
 - https://github.com/torvalds/linux/commit/946e51f2bf37f1656916eb75bd0742ba33983c28


=========================
WHERE TO LOOK FOR UPDATES
=========================
https://github.com/manjaro/packages-core/blob/master/linux318

