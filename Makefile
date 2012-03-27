NOW=       $(shell date +'%y.%m.%d %H:%M:%S')
DIST_FILE= install-accumulo.sh
TMP_FILE=  ${DIST_FILE}.tmp
DIST_DIR=  dist
USER=      $(shell git config user.name)
DIST=      ${DIST_DIR}/${DIST_FILE}

test :
	./test/test-cli-options.sh

dist :
	test -d ${DIST_DIR} || mkdir ${DIST_DIR}
	cat bin/install.sh > ${DIST_DIR}/${TMP_FILE}
	echo "# built ${NOW} by ${USER}" >> ${DIST_DIR}/${TMP_FILE}
	mv ${DIST_DIR}/${TMP_FILE} ${DIST}
	# replace the sourced files
	awk '/source .*?utils.sh/{system("cat bin/utils.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	chmod 755 ${DIST}

clean :
	rm -rf ${DIST_DIR}

.PHONY: test
