NOW= $(shell date +'%y.%m.%d %H:%M:%S')
DIST_FILE= "install-accumulo.sh"
TMP_FILE= "${DIST_FILE}.tmp"
DIST_DIR= "dist"
USER=$(shell git config user.name)

test :
	./test/test-cli-options.sh

dist :
	test -d ${DIST_DIR} || mkdir ${DIST_DIR}
	cat install-accumulo.sh > ${DIST_DIR}/${TMP_FILE}
	echo "# built ${NOW} by ${USER}" >> ${DIST_DIR}/${TMP_FILE}
	mv ${DIST_DIR}/${TMP_FILE} ${DIST_DIR}/${DIST_FILE}
	chmod 755 ${DIST_DIR}/${DIST_FILE}

clean :
	rm -rf ${DIST_DIR}

.PHONY: test
