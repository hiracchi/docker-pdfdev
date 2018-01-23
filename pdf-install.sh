#!/bin/bash

set -e # stop on error
#set -u # inform undefined variables
#set -x # output command

TEMP=/tmp
BRANCH="master"

GITHUB_PROTEINDF="https://github.com/ProteinDF/ProteinDF.git"
GITHUB_PROTEINDF_PYTOOLS="https://github.com/ProteinDF/ProteinDF_pytools.git"
GITHUB_PROTEINDF_BRIDGE="https://github.com/ProteinDF/ProteinDF_bridge.git"
GITHUB_QCLOBOT="https://github.com/ProteinDF/QCLObot.git"

PYTHON="python3"
export F77=gfortran
export FC=gfortran
export CC=gcc
export CXX=g++
export CFLAGS="-Wall -O3 -fopenmp -DMPICH_IGNORE_CXX_SEEK"
export CXXFLAGS="${CFLAGS} -std=c++11"
export CXXFLAGS=${CFLAGS}
export LIBS="-lgfortran -lm -static-libgcc"
export BLAS_LIBS="-lblas"
export LAPACK_LIBS="-llapack"
export SCALAPACK_LIBS="-lscalapack-openmpi -lblacs-openmpi -lblacsCinit-openmpi -lblacsF77init-openmpi -lblacs-openmpi"

CONFIGURE_OPT=" \
 --prefix=${PDF_HOME} \
 --enable-parallel \
 --with-blas \
 --with-lapack \
 --with-scalapack \
 "


git_clone()
{
    REPOS=${1}
    BRANCH=${2}
    DEST=${3}

    BRANCH=${BRANCH:-master}
    DEST=${DEST:-`pwd`}

    if [ -d "${DEST}" ]; then
        echo "already exist: ${DEST}"
        echo "stop to clone..."
        return
    fi

    echo "cloning from ${REPOS} (${BRANCH}) to ${DEST} ..."
    git clone --depth 1 -b ${BRANCH} ${REPOS} ${DEST}
}


install_pdf_by_automake()
{
    if [ -d autom4te.cache ]; then
        rm -rf autom4te.cache
    fi
    ./bootstrap.sh

    mkdir build
    cd build

    ../configure ${CONFIGURE_OPT}
    make -j 3 && make install
}


install_pdf_by_cmake()
{
    mkdir build
    cd build
    cmake \
        -DCMAKE_INSTALL_PREFIX=${PDF_HOME} \
        -DSCALAPACK_LIBRARIES="${SCALAPACK_LIBS}" \
        ..
    make -j 3 && make install
}


install_pdfpyapp()
{
    ${PYTHON} setup.py build install --prefix=${PDF_HOME}
}


# option ==============================================================
declare -a ARGV=()
OPT_W=""
OPT_CLONE_ONLY=""
OPT_BRANCH=""
OPT_CMAKE=""

for OPT in "$@"; do
    case "$OPT" in
        '-w'|'--work')
            if [[ -z "${2}" ]] || [[ "${2}" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- ${1}" 1>&2
                exit 1
            fi
            OPT_W="$2"
            shift 2
            ;;

        '--clone-only')
            OPT_CLONE_ONLY="yes"
            shift 1
            ;;

        '--branch')
            if [[ -z "${2}" ]] || [[ "${2}" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- ${1}" 1>&2
                exit 1
            fi
            OPT_BRANCH="$2"
            shift 2
            ;;

        '--use-cmake')
            OPT_CMAKE="yes"
            shift 1
            ;;

        '--'|'-')
            shift 1
            ARGV+=( "$@" )
            break
            ;;
        -*)
            echo "unknown option: ${1}"
            exit 1
            ;;
        *)
            if [[ ! -z "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                ARGV=("${ARGV[@]}" "$1")
                shift 1
            fi
            ;;
    esac
done
ARGC=${#ARGV[@]}
#echo "ARGC=${ARGC}"
#echo "ARGV[@]=${ARGV[@]}"

WORKDIR=""
if [ -n "${OPT_W}" ]; then
    WORKDIR=${OPT_W}
fi

if [ -n "${OPT_BRANCH}" ]; then
    BRANCH="${OPT_BRANCH}"
fi


# MAIN =================================================================
for CMD in ${ARGV[@]}; do
    case "${CMD}" in
        "pdf")
            if [ "x${WORKDIR}" == x ]; then
                WORKDIR=${TEMP}/pdf
            fi
            git_clone "${GITHUB_PROTEINDF}" "${BRANCH}" ${WORKDIR}
            if [ "x${OPT_CLONE_ONLY}" != xyes ]; then
                (cd ${WORKDIR}; \
                 if [ "x${OPT_CMAKE}" != "xyes" ]; then \
                     install_pdf_by_automake; \
                 else \
                     install_pdf_by_cmake; \
                 fi \
                )
            fi
            ;;

        "pytools")
            if [ "x${WORKDIR}" == x ]; then
                WORKDIR=${TEMP}/pdfpytools
            fi
            git_clone "${GITHUB_PROTEINDF_PYTOOLS}" "${BRANCH}" ${WORKDIR}
            if [ "x${OPT_CLONE_ONLY}" != xyes ]; then
                (cd ${WORKDIR}; install_pdfpyapp)
            fi
            ;;

        "bridge")
            if [ "x${WORKDIR}" == x ]; then
                WORKDIR=${TEMP}/pdfbridge
            fi
            git_clone "${GITHUB_PROTEINDF_BRIDGE}" "${BRANCH}" ${WORKDIR}
            if [ "x${OPT_CLONE_ONLY}" != xyes ]; then
                (cd ${WORKDIR}; install_pdfpyapp)
            fi
            ;;

        "qclobot")
            if [ "x${WORKDIR}" == x ]; then
                WORKDIR=${TEMP}/qclobot
            fi
            git_clone "${GITHUB_QCLOBOT}" "${BRANCH}" ${WORKDIR}
            if [ "x${OPT_CLONE_ONLY}" != xyes ]; then
                (cd ${WORKDIR}; install_pdfpyapp)
            fi
            ;;

        *)
            echo "ignore unknown command: ${CMD}"
            ;;
    esac
done
