# Generate the xyzwi files

-- note that this is different for NGC and SGC since the
-- NGC requires three files to be concatenated...

rdmd code/mk_rdzw_ini_sgc.d 1 1000 /project/projectdirs/boss/galaxy/QPM/dr12d_combined/sgc/qpm_biasmock_%04d.dr12d_combined_sgc.rdzw sgc/qpm_biasmock_%04d.dr12d_combined_sgc.xyzwi ini/xyzwi.hdr ini/xyzwi-sgc-%d.ini 0 100


# Generate the ini files for paircounting
