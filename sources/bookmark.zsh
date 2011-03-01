#
# zaw-src-bookmark
#
# bookmark your favorite command lines, access it using zaw interface
#

zmodload zsh/system

BOOKMARKFILE="${HOME}/.zaw-bookmarks"

function zaw-src-bookmark() {
    if [[ -f "${BOOKMARKFILE}" ]]; then
        candidates=("${(Qf)$(zsystem flock -r "${BOOKMARKFILE}" && < "${BOOKMARKFILE}")}")
    fi
    actions=("zaw-callback-execute" "zaw-callback-replace-buffer" "zaw-callback-append-to-buffer" "zaw-bookmark-remove")
    act_descriptions=("execute" "replace edit buffer" "append to edit buffer" "removed bookmark")
}

zaw-register-src -n bookmark zaw-src-bookmark


#
# helper functions for bookmark
#

function zaw-bookmark-add() {
    local -a bookmarks

    : >> "${BOOKMARKFILE}"
    (
        if zsystem flock -t 5 "${BOOKMARKFILE}"; then
            bookmarks=("${(f)$(< "${BOOKMARKFILE}")}" "${(q@)@}")

            # remove empty lines
            bookmarks=("${(@)bookmarks:#}")

            # remove duplicated lines, sort and write to ${BOOKMARKFILE}
            print -rl -- "${(@un)bookmarks}" > "${BOOKMARKFILE}"
        else
            print "can't acquire lock for '${BOOKMARKFILE}'" >&2
            exit 1
        fi
    )

    if [[ $? == 0 ]]; then
        zle -M "bookmark '${(j:', ':)@}'"
    fi
}

function zaw-bookmark-add-buffer() {
    zaw-bookmark-add "${BUFFER}"
}

zle -N zaw-bookmark-add-buffer

function zaw-bookmark-remove() {
    local s
    local -a bookmarks

    : >> "${BOOKMARKFILE}"
    (
        if zsystem flock -t 5 "${BOOKMARKFILE}"; then
            bookmarks=("${(f)$(< "${BOOKMARKFILE}")}")
            for s in "${(q@)@}"; do
                bookmarks=("${(@)bookmarks:#${s}}")
            done

            # remove duplicated lines, sort and write to ${BOOKMARKFILE}
            print -rl -- "${(@un)bookmarks}" > "${BOOKMARKFILE}"
        else
            print "can't acquire lock for '${BOOKMARKFILE}'" >&2
            exit 1
        fi
    )

    if [[ $? == 0 ]]; then
        zle -M "bookmark '${(j:', ':)@}' removed"
    fi
}

function zaw-bookmark-remove-buffer() {
    zaw-bookmark-remove "${BUFFER}"
}

zle -N zaw-bookmark-remove-buffer
