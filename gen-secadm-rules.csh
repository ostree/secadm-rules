#!/usr/bin/env csh

set _rules_file = `mktemp`
set secadm_rules = "/usr/local/etc/secadm.rules"

if ( "X$1" == "Xdebug" ) then
	set debug = 1
else
	set debug = 0
endif

if ( $euser != "root" ) then
	echo "this script needs root user"
	exit 1
endif

if ( ! -f ${_rules_file} ) then
	echo "fail..."
	exit 1
endif

cat > ${_rules_file}<<EOF
secadm {
EOF

foreach i ( *.rule )
	set _bin = `sed -n '/path/s/.*\"\(.*\)\",/\1/p' $i`
	if ( ${debug} == 1 ) then
		echo "try to add ${i} (bin: ${_bin}) rules to ${secadm_rules}"
	endif
	if ( -e ${_bin} ) then
		sed -e 's/^/	/g' ${i} >> ${_rules_file}
		echo "added ${i} rules to ${secadm_rules}"
	else
		echo "skipped ${i}, program does not exists on the system"
	endif
end

cat >> ${_rules_file}<<EOF
}
EOF

echo
echo "--------------------------------------------------"
cat ${_rules_file}
echo "--------------------------------------------------"

again:
printf 'enter \"yes\" if the rules are okay and change the current ruleset or \"no\" when not: '
set _in = $<
if ( ${_in} != "yes" && ${_in} != "no" ) then
	goto again
endif

if ( ${_in} == "yes" ) then
	chflags noschg ${secadm_rules}
	cp ${_rules_file} ${secadm_rules}
	chown root:wheel ${secadm_rules}
	chmod 0500 ${secadm_rules}
	chflags schg ${secadm_rules}
	service secadm restart
endif

rm ${_rules_file}
