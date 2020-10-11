export P=python3
export V=3.9.0
export B=1
export MAINTAINER=JuergenFischer
export BUILDDEPENDS=none

source ../../../scripts/build-helpers

startlog

M=${V%%.*}
VM=${V%.*}
MM=${VM//./}

PREFIX=apps/Python$MM/

exetmpl() {
	local i=$1
	local pkg=$2
	local b=$(basename $i)
	local t=${PREFIX}Scripts/$b

	echo -e "textreplace -std -t ${t///\\}\r" >>$pkg-postinstall.bat
	echo -e "del ${t//\//\\\\}\r" >>$pkg-preremove.bat

	perl -pe "s#${PY//\\/\\\\}#\@osgeo4w\@\\\\apps\\\\Python$MM\\\\python.exe#i" $i >$b.tmpl
	chmod a+rx $b.tmpl
}

export R=$OSGEO4W_REP/x86_64/release/$P
mkdir -p $R

PKG=python-$V-amd64.exe
[ -f $PKG ] || wget https://www.python.org/ftp/python/$V/$PKG
chmod a+rx $PKG

if ! [ -d install ]; then
	d=$(cygpath -aw install)
	./$PKG /quiet TargetDir=${d//\\/\\\\} AssociateFiles=0 Shortcuts=0 SimpleInstall=1
fi

[ -d install ]

for p in core help devel test tcltk tools; do
	mkdir -p $R/$P-$p
	cp install/LICENSE.txt $R/$P-$p/$P-$p-$V-$B.txt
done

PIPV=$(sed -ne "s/^Version: //p" install/Lib/site-packages/pip-*.dist-info/METADATA)
STV=$(sed -ne "s/^Version: //p" install/Lib/site-packages/setuptools-*.dist-info/METADATA)

mkdir -p $R/$P-pip $R/$P-setuptools
cp install/LICENSE.txt $R/$P-pip/$P-pip-$PIPV-$B.txt
cp install/LICENSE.txt $R/$P-setuptools/$P-setuptools-$STV-$B.txt

cat <<EOF >$R/$P-core/setup.hint
sdesc: "Python core interpreter and runtime"
ldesc: "Python core interpreter and runtime"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: msvcrt2019 sqlite3
external-source: $P
EOF

PY=$(cygpath -aw $a/python.exe)

cat <<EOF >tcltk.lst
install/DLLs/_tkinter.pyd
install/DLLs/tcl86t.dll
install/DLLs/tk86t.dll
install/Lib/idlelib
install/tcl
EOF

cat <<EOF >test.lst
install/DLLs/_ctypes_test.pyd
install/DLLs/_testbuffer.pyd
install/DLLs/_testcapi.pyd
install/DLLs/_testconsole.pyd
install/DLLs/_testimportmultiple.pyd
install/DLLs/_testmultiphase.pyd
install/Lib/ctypes/test
install/Lib/distutils/tests
install/Lib/doctest.py
install/Lib/idlelib/idle_test
install/Lib/lib2to3/tests
install/Lib/sqlite3/test
install/Lib/test
install/Lib/tkinter/test
install/Lib/unittest/test
install/tcl/tcl8/8.5/tcltest-2.5.0.tm
install/Tools/scripts/run_tests.py
EOF

cat <<EOF >pip.lst
./pip.exe.tmpl
./pip$M.exe.tmpl
./pip$VM.exe.tmpl
install/Lib/site-packages/pip
install/Lib/site-packages/pip-$PIPV.dist-info
EOF

cat <<EOF >setuptools.lst
easy_install-$VM.exe.tmpl
easy_install.exe.tmpl
install/Lib/site-packages/easy_install.py
install/Lib/site-packages/setuptools
install/Lib/site-packages/setuptools-$STV.dist-info
EOF

cat <<EOF >tools.lst
install/Tools
EOF

cat <<EOF >preremove-cached.py
import importlib.util
import gzip
import os
import sys

cachedirs = {}
with gzip.open("{}/etc/setup/{}.lst.gz".format(os.environ['OSGEO4W_ROOT'], sys.argv[1])) as f:
    for py in f:
        py = py.decode("utf-8").strip()
        if py.endswith(".py"):
            try:
                pyc = importlib.util.cache_from_source(py)
                os.remove(pyc)
                print("Removed {}".format(pyc))
                cachedirs[ os.path.dirname(pyc) ] = 1
            except:
                pass

for cachedir in sorted(cachedirs.keys(), reverse=True):
    try:
        os.rmdir(cachedir)
        print("Removed directory {}".format(cachedir))
    except:
        pass
EOF

#
# core
#

cat <<EOF >ini.bat
SET PYTHONHOME=%OSGEO4W_ROOT%\\apps\\Python$MM
PATH %OSGEO4W_ROOT%\\apps\\Python$MM\Scripts;%PATH%
EOF

cat <<EOF >core-preremove.bat
python -B %OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py $P-core
EOF

cp -a install/python.exe python.exe
cp -a install/pythonw.exe pythonw.exe
tar -cjf $R/$P-core/$P-core-$V-$B.tar.bz2 \
	--xform "s,preremove-cached.py,${PREFIX}Scripts/preremove-cached.py," \
	--xform "s,core-preremove.bat,etc/preremove/$P-core.bat," \
	--xform "s,^install/python.exe,${PREFIX}python.exe," \
	--xform "s,^install/pythonw.exe,${PREFIX}pythonw.exe," \
	--xform "s,^install/python$MM.dll,bin/python$MM.dll," \
	--xform "s,^install/python$M.dll,bin/python$M.dll," \
	--xform "s,^install/,$PREFIX," \
	--xform "s,^python.exe,bin/python.exe," \
	--xform "s,^pythonw.exe,bin/pythonw.exe," \
	--xform "s,ini.bat,etc/ini/$P.bat," \
	--exclude "__pycache__" \
	--exclude install/DLLs/sqlite3.dll \
	--exclude install/DLLs/libcrypto-1_1.dll \
	--exclude install/DLLs/libssl-1_1.dll \
	--exclude-from tcltk.lst \
	--exclude-from test.lst \
	--exclude-from pip.lst \
	--exclude-from setuptools.lst \
	--exclude-from tools.lst \
	preremove-cached.py \
	core-preremove.bat \
	ini.bat \
	install/LICENSE.txt \
	install/DLLs \
	install/Lib \
	install/python.exe \
	install/pythonw.exe \
	python.exe \
	pythonw.exe \
	install/python$MM.dll \
	install/python$M.dll

#
# help
#

cat <<EOF >$R/$P-help/setup.hint
sdesc: "Python documentation in a Windows compiled help file"
ldesc: "Python documentation in a Windows compiled help file"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: $P-core
external-source: $P
EOF

tar -cjf $R/$P-help/$P-help-$V-$B.tar.bz2 \
	--xform "s,^install/,$PREFIX," \
	install/Doc/ \
	install/NEWS.txt

#
# devel
#


cat <<EOF >$R/$P-devel/setup.hint
sdesc: "Python library and header files"
ldesc: "Python library and header files"
maintainer: $MAINTAINER
category: Libs
requires: $P-core
external-source: $P
EOF

tar -cjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 \
	--xform "s,^install/,$PREFIX," \
	install/include \
	install/libs

#
# test
#

cat <<EOF >$R/$P-test/setup.hint
sdesc: "Python self tests"
ldesc: "Python self tests"
maintainer: $MAINTAINER
category: Libs
requires: $P-core
external-source: $P
EOF

cat <<EOF >test-preremove.bat
python -B %OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py $P-test
EOF

tar -cjf $R/$P-test/$P-test-$V-$B.tar.bz2 \
	--xform "s,test-preremove.bat,etc/preremove/$P-test.bat," \
	--xform "s,^install/,$PREFIX," \
	--exclude "__pycache__" \
	-T test.lst \
	test-preremove.bat

#
# tcltk & idle
#

cat <<EOF >$R/$P-tcltk/setup.hint
sdesc: "Python Tkinter and IDLE"
ldesc: "Python Tkinter and IDLE"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: $P-core
external-source: $P
EOF

cat <<EOF >tcltk-preremove.bat
python -B %OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py $P-tcltk
EOF

tar -cjf $R/$P-tcltk/$P-tcltk-$V-$B.tar.bz2 \
	--xform "s,tcltk-preremove.bat,etc/preremove/$P-tcltk.bat," \
	--xform "s,^install/,$PREFIX," \
	--exclude "__pycache__" \
	--exclude-from "test.lst" \
	-T tcltk.lst \
	tcltk-preremove.bat

#
# tools
#

cat <<EOF >$R/$P-tools/setup.hint
sdesc: "Python Tools"
ldesc: "Python Tools"
maintainer: $MAINTAINER
category: Commandline_Utilities
requires: $P-core
external-source: $P
EOF

cat <<EOF >tools-preremove.bat
python -B %OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py $P-tools
EOF

tar -cjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 \
	--xform "s,tools-preremove.bat,etc/preremove/$P-tools.bat," \
	--xform "s,^install/,$PREFIX," \
	--exclude "__pycache__" \
	--exclude-from tcltk.lst \
	--exclude-from test.lst \
	install/Tools \
	tools-preremove.bat

#
# pip
#

rm -f pip-postinstall.bat

cat <<EOF >pip-preremove.bat
python -B %OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py $P-pip
EOF

exetmpl install/Scripts/pip.exe pip
exetmpl install/Scripts/pip$M.exe pip
exetmpl install/Scripts/pip$VM.exe pip


cat <<EOF >$R/$P-pip/setup.hint
sdesc: "The PyPA recommended tool for installing Python packages."
ldesc: "The PyPA recommended tool for installing Python packages."
maintainer: $MAINTAINER
category: Libs
requires: $P-core
EOF

tar -cjf $R/$P-pip/$P-pip-$PIPV-$B.tar.bz2 \
	--xform "s,^pip-postinstall.bat,etc/postinstall/$P-pip.bat," \
	--xform "s,^pip-preremove.bat,etc/preremove/$P-pip.bat," \
	--xform s,^./pip.exe.tmpl,${PREFIX}Scripts/pip.exe.tmpl, \
	--xform s,^./pip$M.exe.tmpl,${PREFIX}Scripts/pip$M.exe.tmpl, \
	--xform s,^./pip$VM.exe.tmpl,${PREFIX}Scripts/pip$VM.exe.tmpl, \
	--xform "s,^install/,$PREFIX," \
	--exclude "__pycache__" \
	-T pip.lst \
	pip-postinstall.bat \
	pip-preremove.bat

tar -C .. -cjf $R/$P-pip/$P-pip-$PIPV-$B-src.tar.bz2 osgeo4w/package.sh

#
# setuptools
#

rm -f setuptools-postinstall.bat

cat <<EOF >setuptools-preremove.bat
python -B %OSGEO4W_ROOT%\\apps\\Python$MM\\Scripts\\preremove-cached.py $P-setuptools
EOF

exetmpl install/Scripts/easy_install-$VM.exe setuptools
exetmpl install/Scripts/easy_install.exe setuptools

cat <<EOF >$R/$P-setuptools/setup.hint
sdesc: "setuptools - Easily download, build, install, upgrade, and uninstall Python packages"
ldesc: "setuptools - Easily download, build, install, upgrade, and uninstall Python packages"
maintainer: $MAINTAINER
category: Libs
requires: $P-core
EOF

tar -cjf $R/$P-setuptools/$P-setuptools-$STV-$B.tar.bz2 \
	--xform "s,^setuptools-postinstall.bat,etc/postinstall/$P-setuptools.bat," \
	--xform "s,^setuptools-preremove.bat,etc/preremove/$P-setuptools.bat," \
	--xform "s,^easy_install-$VM.exe.tmpl,${PREFIX}Scripts/easy_install-$VM.exe.tmpl," \
	--xform "s,^easy_install.exe.tmpl,${PREFIX}Scripts/easy_install.exe.tmpl," \
	--xform "s,^install/,$PREFIX," \
	--exclude "__pycache__" \
	setuptools-postinstall.bat \
	setuptools-preremove.bat \
	-T setuptools.lst

tar -C .. -cjf $R/$P-setuptools/$P-setuptools-$STV-$B-src.tar.bz2 osgeo4w/package.sh

#
# check
#

find install -type f | sed -e '/\.pyc$/d; s#^install/##;' >/tmp/$P-installed.lst
	
(
	tar -tjf $R/$P-core/$P-core-$V-$B.tar.bz2 | sed -e "s/$/:core/"
	tar -tjf $R/$P-help/$P-help-$V-$B.tar.bz2 | sed -e "s/$/:help/"
	tar -tjf $R/$P-devel/$P-devel-$V-$B.tar.bz2 | sed -e "s/$/:devel/"
	tar -tjf $R/$P-test/$P-test-$V-$B.tar.bz2 | sed -e "s/$/:test/"
	tar -tjf $R/$P-tcltk/$P-tcltk-$V-$B.tar.bz2 | sed -e "s/$/:tcltk/"
	tar -tjf $R/$P-tools/$P-tools-$V-$B.tar.bz2 | sed -e "s/$/:tools/"
	tar -tjf $R/$P-pip/$P-pip-$PIPV-$B.tar.bz2 | sed -e "s/$/:pip/"
	tar -tjf $R/$P-setuptools/$P-setuptools-$STV-$B.tar.bz2 | sed -e "s/$/:setuptools/"
) | egrep -v '(\/|\.pyc):' | sort >/tmp/$P-packaged.lst

cut -d: -f1 /tmp/$P-packaged.lst | sort | uniq -d >/tmp/$P-dupes.lst
if [ -s /tmp/$P-dupes.lst ]; then
	echo DUPES:
	grep -f <(sed -e 's/^/^/; s/$/:/;' /tmp/$P-dupes.lst) /tmp/$P-packaged.lst | sort
fi

egrep -v -f \
	<(sed -e 's/:.*$//; /\.pyc$/d; s#^'$PREFIX'##; s/[/+.$]/\\&/g; s/(dev)/\\(dev\\)/; s/$/$/;' /tmp/$P-packaged.lst) \
	/tmp/$P-installed.lst \
	>/tmp/$P-unpackaged.lst
if [ -s /tmp/$P-unpackaged.lst ]; then
	echo UNPACKAGED:
	cat /tmp/$P-unpackaged.lst
fi

egrep -v -f \
	<(sed -e '/\.pyc$/d; s#^#^('$PREFIX'|)#; s/[/+.$]/\\&/g; s/(dev)/\\(dev\\)/; s/$/$/;' /tmp/$P-installed.lst) \
	<(cut -d: -f1 /tmp/$P-packaged.lst) \
	>/tmp/$P-generated.lst
if [ -s /tmp/$P-generated.lst ]; then
	echo GENERATED:
	cat /tmp/$P-generated.lst
fi

endlog