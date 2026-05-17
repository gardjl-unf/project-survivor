#!/usr/bin/env bash
set -euo pipefail

NODE_EDITOR_DIR="${1:?usage: patch_imgui_node_editor_compat.sh <imgui-node-editor-dir>}"
CPP_FILE="${NODE_EDITOR_DIR}/imgui_node_editor.cpp"

if [[ ! -f "${CPP_FILE}" ]]; then
    echo "imgui-node-editor compatibility patch failed: missing ${CPP_FILE}" >&2
    exit 1
fi

perl -pi -e 's/ImGui::IsKeyPressed\(ImGui::GetKeyIndex\((ImGuiKey_[A-Za-z0-9_]+)\)\)/ImGui::IsKeyPressed($1)/g' "${CPP_FILE}"

if ! rg -q "floor_im_rect" "${CPP_FILE}"; then
    perl -0pi -e 's/# include <type_traits>\n/# include <type_traits>\n\nstatic inline void floor_im_rect(ImRect* rect)\n{\n    if (rect == nullptr)\n        return;\n    rect->Min = ImFloor(rect->Min);\n    rect->Max = ImFloor(rect->Max);\n}\n\n/s' "${CPP_FILE}"
fi

perl -pi -e 's/node->m_Bounds\.Floor\(\);/floor_im_rect\(&node->m_Bounds\);/g' "${CPP_FILE}"
perl -pi -e 's/node->m_GroupBounds\.Floor\(\);/floor_im_rect\(&node->m_GroupBounds\);/g' "${CPP_FILE}"
perl -pi -e 's/newBounds\.Floor\(\);/floor_im_rect\(&newBounds\);/g' "${CPP_FILE}"
perl -pi -e 's/m_NodeRect\.Floor\(\);/floor_im_rect\(&m_NodeRect\);/g' "${CPP_FILE}"
perl -pi -e 's/m_CurrentPin->m_Bounds\.Floor\(\);/floor_im_rect\(&m_CurrentPin->m_Bounds\);/g' "${CPP_FILE}"
perl -pi -e 's/m_GroupBounds\.Floor\(\);/floor_im_rect\(&m_GroupBounds\);/g' "${CPP_FILE}"
