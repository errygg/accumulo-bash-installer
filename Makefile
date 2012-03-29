.PHONY : test clean dist

NOW=       $(shell date +'%y.%m.%d %H:%M:%S')
DIST_FILE= install-accumulo.sh
TMP_FILE=  ${DIST_FILE}.tmp
DIST_DIR=  dist
USER=      $(shell git config user.name)
DIST=      ${DIST_DIR}/${DIST_FILE}

test :
	./test/all.sh

clean :
	rm -rf ${DIST_DIR}

_dist :
	test -d ${DIST_DIR} || mkdir ${DIST_DIR}
	cat bin/install.sh > ${DIST_DIR}/${TMP_FILE}
	echo "# built ${NOW} by ${USER}" >> ${DIST_DIR}/${TMP_FILE}
	mv ${DIST_DIR}/${TMP_FILE} ${DIST}
	awk '/source .*?utils.sh/{system("cat bin/utils.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	awk '/source .*?apache_downloader.sh/{system("cat bin/apache_downloader.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	awk '/source .*?pre_install.sh/{system("cat bin/pre_install.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	awk '/source .*?hadoop.sh/{system("cat bin/hadoop.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	awk '/source .*?zookeeper.sh/{system("cat bin/zookeeper.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	awk '/source .*?accumulo.sh/{system("cat bin/accumulo.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	awk '/source .*?post_install.sh/{system("cat bin/post_install.sh");next}1' ${DIST} > ${DIST}.1 && mv ${DIST}.1 ${DIST}
	chmod 755 ${DIST}

dist : | clean _dist
