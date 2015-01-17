#!/bin/bash
#
# Copyright (C) 2015 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
#

# apply official Magento CE patches to downloaded archives?
APPLY_PATCHES="${APPLY_PATCHES:-true}"
# mirror Magento sample data?
MAGE_SAMPLE_DATA="${MAGE_SAMPLE_DATA:-true}"
# use 1.9.x sample data without the greasy mp3 stuff? see: https://github.com/Vinai/compressed-magento-sample-data
VINAI_AWESOMENESS="${VINAI_AWESOMENESS:-true}"
# which Magento versions to mirror
MIRROR_VERSIONS="${MIRROR_VERSIONS:-
1.6.0.0
1.6.1.0
1.6.2.0
1.7.0.0
1.7.0.1
1.7.0.2
1.8.0.0
1.8.1.0
1.9.0.0
1.9.0.1
1.9.1.0
}"
# create a flat mirror instead of duplicating the official Magento mirror structure?
FLAT_MIRROR="${FLAT_MIRROR:-false}"
# Some patches depend on other patches being applied first
# key: patchfile value: dependency (substring matched)
declare -A PATCH_DEPENDENCIES
PATCH_DEPENDENCIES=(
    ["1.7.0.0-1.8.1.0/PATCH_SUPEE-4334_EE_1.11.0.0-1.13.0.2_v1.sh"]="PATCH_SUPEE-1868_EE"
)

MAGE_URL="${MAGE_URL:-http://www.magentocommerce.com/downloads/assets}"

die()
{
    echo "$1"
    exit 1
}

msg()
{
    echo "--> $@"
}

# Compare version strings, returns true if greater or equal
# Taken from http://stackoverflow.com/a/24067243, modified for busybox
version_gt() { test "$(echo "$@" | tr " " "\n" | sort | tail -n 1)" == "$1"; }

# Returns 0 if given string contains given word. Does not match substrings.
#
# Arguments:
# 1: STRING
# 2: WORD
string_has_word() {
    regex="(^| )${2}($| )"
    if [[ "${1}" =~ $regex ]];then
        return 0
    else
        return 1
    fi
}

# Returns patches suitable for given $MAGE_VERSION
# 
# Arguments:
# 1: MAGE_VERSION
find_patches() {
    VERSION="${1}"
    PATCHES=()
    cd ${PATCHES_PATH}
    for PATCH_DIR in *; do
        PATCH_VERSION_RANGE=(${PATCH_DIR//-/ })
        LOWER_LIMIT=${PATCH_VERSION_RANGE[0]}
        UPPER_LIMIT=${PATCH_VERSION_RANGE[1]}

        if [ "${VERSION}" == "${LOWER_LIMIT}" ] || [ "${VERSION}" == "${UPPER_LIMIT}" ] || \
            (version_gt $VERSION ${LOWER_LIMIT} && ! version_gt $VERSION ${UPPER_LIMIT}); then

            for PATCH in $PATCH_DIR/*; do
                PATCHES+=($PATCH)
            done
        fi
    done
    printf -v PATCHES "%s " "${PATCHES[@]}"
    PATCHES=${PATCHES%?}

    PATCHES_SORTED=""
    # generate patch order
    for PATCH in $PATCHES; do
        check_patch_dependencies ${PATCH}
        if [ -z "$PATCHES_SORTED" ]; then
            PATCHES_SORTED="${PATCH}"
        else
            ! string_has_word "${PATCHES_SORTED}" ${PATCH} && PATCHES_SORTED+=" ${PATCH}"
        fi
    done
    echo "${PATCHES_SORTED}"
}

# Check patch dependencies and populate PATCHES_SORTED. Recursive.
#
# Arguments:
#
# 1: PATCH
check_patch_dependencies() {
    local PATCH="${1}"
    if [ ${PATCH_DEPENDENCIES[$PATCH]+abc} ] && [[ "${PATCHES}" =~ ${PATCH_DEPENDENCIES[$PATCH]} ]]; then
        regex=[[:space:]]?\([a-zA-Z0-9_\/\.\-]*${PATCH_DEPENDENCIES[$PATCH]}[a-zA-Z0-9_\/\.\-]*\)[[:space:]]?
        if [[ "${PATCHES}" =~ $regex ]]; then
            match="${BASH_REMATCH[1]}"
            # skip further checking if already processed
            if ! string_has_word "${PATCHES_SORTED}" ${PATCH}; then
                # check for further patch dependencies
                [ ${PATCH_DEPENDENCIES[$match]+abc} ] && check_patch_dependencies $match
                PATCHES_SORTED+=" ${match}";
            fi
        fi
    fi
}

REQUIRED_BINARIES="sort tar tail tr wget"
for BINARY in ${REQUIRED_BINARIES}; do
    if ! [ -x "$(command -v ${BINARY})" ]; then
        die "${BINARY} is required for this script to run."
    fi
done

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DL_PATH="${DL_PATH:-$PROJECT_DIR/downloads}"
TMP_PATH="${TMP_PATH:-$PROJECT_DIR/tmp}"
PATCHES_PATH="${PATCHES_PATH:-$PROJECT_DIR/patches}"
MIRROR_PATH="${MIRROR_PATH:-$PROJECT_DIR/mirror}"
VINAI_REPO_URL="https://raw.githubusercontent.com/Vinai/compressed-magento-sample-data"

rm -rf "${MIRROR_PATH}"
mkdir -p "${DL_PATH}" "${MIRROR_PATH}" "${TMP_PATH}"

for MAGE_VERSION in ${MIRROR_VERSIONS}; do
    MAGE_FILE_NAME=magento-${MAGE_VERSION}.tar.gz
    if [ ! -f ${DL_PATH}/${MAGE_FILE_NAME} ]; then
    msg "downloading: ${MAGE_FILE_NAME} (progress bar won't display in logs)"
    wget -O ${DL_PATH}/${MAGE_FILE_NAME} ${MAGE_URL}/${MAGE_VERSION}/${MAGE_FILE_NAME} || \
        die "error downloading ${MAGE_URL}/${MAGE_VERSION}/${MAGE_FILE_NAME}"
    else
        msg "found: ${MAGE_FILE_NAME}"
    fi

    # sample data
    if [[ "${MAGE_SAMPLE_DATA}" == 'true' ]]; then
        if version_gt ${MAGE_VERSION} "1.9.1.0"; then
            SAMPLE_DATA_VERSION=1.9.1.0
        elif version_gt ${MAGE_VERSION} "1.9.0.0"; then
            SAMPLE_DATA_VERSION=1.9.0.0
        elif version_gt ${MAGE_VERSION} "1.6.0.0"; then
            SAMPLE_DATA_VERSION=1.6.1.0
        else
            SAMPLE_DATA_VERSION=1.2.0.0
        fi

        if [[ "${FLAT_MIRROR}" == 'false' ]]; then
            SAMPLE_MIRROR_PATH="${MIRROR_PATH}/$SAMPLE_DATA_VERSION"
            mkdir -p "$SAMPLE_MIRROR_PATH"
        else
            SAMPLE_MIRROR_PATH="${MIRROR_PATH}"
        fi
        SAMPLE_DATA_FILENAME="magento-sample-data-${SAMPLE_DATA_VERSION}.tar.gz"

        if ([[ "${SAMPLE_DATA_VERSION}" == "1.9.0.0" ]] || version_gt ${SAMPLE_DATA_VERSION} "1.9.0.0") && \
            [[ "${VINAI_AWESOMENESS}" == 'true' ]]; then

            SAMPLE_DATA_FILENAME_SRC="compressed-no-mp3-magento-sample-data-${SAMPLE_DATA_VERSION}.tgz"
            SAMPLE_DATA_URL="${VINAI_REPO_URL}/${SAMPLE_DATA_VERSION}/${SAMPLE_DATA_FILENAME_SRC}"
        else
            SAMPLE_DATA_FILENAME_SRC="${SAMPLE_DATA_FILENAME}"
            SAMPLE_DATA_URL="${MAGE_URL}/${SAMPLE_DATA_VERSION}/${SAMPLE_DATA_FILENAME}"
        fi

        if [ ! -f ${DL_PATH}/${SAMPLE_DATA_FILENAME_SRC} ]; then
            msg "downloading: ${SAMPLE_DATA_FILENAME_SRC} (progress bar won't display in logs)"
            wget -O ${DL_PATH}/${SAMPLE_DATA_FILENAME_SRC} ${SAMPLE_DATA_URL} || \
                die "error downloading ${SAMPLE_DATA_URL}"
        else
            msg "found: ${SAMPLE_DATA_FILENAME_SRC}"
        fi

        if [ ! -f ${SAMPLE_MIRROR_PATH}/${SAMPLE_DATA_FILENAME} ]; then
            cp ${DL_PATH}/${SAMPLE_DATA_FILENAME_SRC} ${SAMPLE_MIRROR_PATH}/${SAMPLE_DATA_FILENAME}
        fi
    fi

    if [[ "${FLAT_MIRROR}" == 'false' ]]; then
        MIRROR_PATH_FULL="${MIRROR_PATH}/${MAGE_VERSION}"
        mkdir -p "${MIRROR_PATH_FULL}"
    else
        MIRROR_PATH_FULL="${MIRROR_PATH}"
    fi

    # apply patches
    if [[ "${APPLY_PATCHES}" == 'true' ]]; then
        msg "extract: ${MAGE_FILE_NAME}"
        rm -rf "${TMP_PATH}/magento"
        tar -xpf "${DL_PATH}/${MAGE_FILE_NAME}" -C ${TMP_PATH}
        cd "${TMP_PATH}/magento"
        msg "apply patches:"
        PATCHES=$(find_patches ${MAGE_VERSION})
        for PATCH in $PATCHES; do
            echo ${PATCH}
            PATCH_FILE=$(basename $PATCH)
            cp "${PATCHES_PATH}/${PATCH}" "$TMP_PATH/magento"
            bash ${PATCH_FILE} || die "error applying patch: ${PATCH}"
            rm "${TMP_PATH}/magento/${PATCH_FILE}"
        done
        cd "${PROJECT_DIR}"
        tar -cpzf "${MIRROR_PATH_FULL}/${MAGE_FILE_NAME}" -C "${TMP_PATH}" magento/
        rm -rf "${TMP_PATH}/magento"
    else
        cp "${DL_PATH}/${MAGE_FILE_NAME}" "${MIRROR_PATH_FULL}/${MAGE_FILE_NAME}"
    fi
done

echo ""
msg "Magento mirror successfully build at: ${MIRROR_PATH}"
