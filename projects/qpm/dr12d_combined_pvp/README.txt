# Generate the xyzwi files

-- note that this is different for NGC and SGC since the
-- NGC requires three files to be concatenated...

rdmd code/mk_rdzw_ini_ngc.d 1 1000 /project/projectdirs/boss/galaxy/QPM/dr12d_combined/ngc/qpm_biasmock_%04d.dr12d_combined_ngc%%s.rdzw ngc/qpm_biasmock_%04d.dr12d_combined_ngc.xyzwi ini/xyzwi.hdr ini/xyzwi-ngc-%d.ini 0 100
rdmd code/mk_rdzw_ini_sgc.d 1 1000 /project/projectdirs/boss/galaxy/QPM/dr12d_combined/sgc/qpm_biasmock_%04d.dr12d_combined_sgc.rdzw sgc/qpm_biasmock_%04d.dr12d_combined_sgc.xyzwi ini/xyzwi.hdr ini/xyzwi-sgc-%d.ini 0 100


# Generate the ini files for paircounting
rdmd code/mk_unrecon_paircount.d 1 1000 ngc/qpm_biasmock_%04d.dr12d_combined_ngc.xyzwi randoms/qpm_dr12d_combined_randoms_x50_ngc.xyzwi paircounts/ngc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-ngc-%02d.ini 0
rdmd code/mk_unrecon_paircount.d 1 1000 sgc/qpm_biasmock_%04d.dr12d_combined_sgc.xyzwi randoms/qpm_dr12d_combined_randoms_x50_sgc.xyzwi paircounts/sgc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-sgc-%02d.ini 0


rdmd code/mk_unrecon_paircount.d 101 1000 ngc/qpm_biasmock_%04d.dr12d_combined_ngc.xyzwi randoms/qpm_dr12d_combined_randoms_x50_ngc.xyzwi paircounts/ngc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-ngc-%02d.ini 2
rdmd code/mk_unrecon_paircount.d 101 1000 sgc/qpm_biasmock_%04d.dr12d_combined_sgc.xyzwi randoms/qpm_dr12d_combined_randoms_x50_sgc.xyzwi paircounts/sgc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-sgc-%02d.ini 2

rdmd code/mk_unrecon_paircount.d 1 1000 ngc/qpm_biasmock_%04d.dr12d_combined_ngc.xyzwi randoms/qpm_dr12d_combined_randoms_x50_ngc.xyzwi paircounts/ngc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-ngc-%02d.ini 20


## Archive files
htar -cf 2015/boss/QPM/dr12d_combined_zweight_qpmcosmo_unrecon00.tar -L qpmcosmo/code/qpmcosmo_unrecon00.txt 
