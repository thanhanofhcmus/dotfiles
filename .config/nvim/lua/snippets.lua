local cmp = require('cmp')

local cpp_snippets = {
    {
        label = 'cptpl',
        description = 'Competitive programming template',
        body = [[
#include <bits/stdc++.h>
using namespace std;

using ll = long long;
using ull = unsigned long long;
using pii = pair<int, int>;
using pll = pair<ll, ll>;
using vi = vector<int>;
using vll = vector<ll>;

const ll INF = 4e18;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    ${0}

    return 0;
}
]],
    },
}

local source = {}

source.new = function()
    return setmetatable({}, { __index = source })
end

function source:is_available()
    return vim.bo.filetype == 'cpp'
end

function source:complete(_, callback)
    local items = {}
    for _, s in ipairs(cpp_snippets) do
        table.insert(items, {
            label = s.label,
            kind = cmp.lsp.CompletionItemKind.Snippet,
            insertText = s.body,
            insertTextFormat = cmp.lsp.InsertTextFormat.Snippet,
            documentation = { kind = 'markdown', value = '```cpp\n' .. s.body .. '\n```' },
        })
    end
    callback(items)
end

cmp.register_source('cpp_snippets', source.new())
