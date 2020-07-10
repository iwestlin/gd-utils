module.exports = { gen_tree_html }

function gen_tree_html (arr) {
  const data = gen_tree_data(arr, is_gd_folder)
  return tree_tpl(JSON.stringify(data))
}

function tree_tpl (str) {
  return `<!doctype html>
<html>

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1,shrink-to-fit=no">
    <meta name="theme-color" content="#000000">
    <title>Folder Tree</title>
    <link href="https://cdn.jsdelivr.net/gh/iwestlin/gd-utils/static/tree.min.css" rel="stylesheet">
</head>

<body>
    <!-- source code: https://github.com/iwestlin/foldertree/blob/master/app.jsx -->
    <div id="root"></div>
    <script type="text/javascript">
    var treedata = ${str}
    </script>
    <script type="text/javascript" src="https://cdn.jsdelivr.net/gh/iwestlin/gd-utils/static/tree.min.js"></script>
</body>

</html>`
}

function is_gd_folder (data) {
  return data.mimeType === 'application/vnd.google-apps.folder'
}

function gen_tree_data (data, is_folder) {
  if (!data || !data.length) return []
  const folders = data.filter(is_folder)
  const files = data.filter(v => !is_folder(v))
  const total_size = sum(files.map(v => v.size))
  const root = {
    title: `/根目录 [共${files.length} 个文件（不包括文件夹）, ${format_size(total_size)}]`,
    key: data[0].parent
  }
  if (!folders.length) return [root]
  const sub_folders = folders.filter(v => v.parent === folders[0].parent)
  sub_folders.forEach(v => {
    sum_files(v, data, is_folder)
    count_files(v, data, is_folder)
  })
  sort_folders(folders, 'count')
  sort_folders(sub_folders, 'count')
  folders.forEach(v => {
    let {name, size, count, id} = v
    if (name.length > 50) name = name.slice(0, 48) + '...'
    v.title = `${name} | [共${count}个文件 ${format_size(size)}]`
  })
  root.children = sub_folders.map(v => gen_node(v, folders))
  return [root]
}

function sort_folders (folders, type) {
  if (!folders || !folders.length) return
  if (type === 'size') return folders.sort((a, b) => b.size - a.size)
  if (type === 'count') return folders.sort((a, b) => b.count - a.count)
}

function gen_node (v, folders) {
  const {id, title, node} = v
  if (node) return node
  return v.node = {
    title,
    key: id,
    children: v.children || folders.filter(vv => vv.parent === id).map(vv => gen_node(vv, folders))
  }
}

function count_files (folder, arr, is_folder) {
  if (folder.count) return folder.count
  const children = arr.filter(v => v.parent === folder.id)
  return folder.count = sum(children.map(v => {
    if (is_folder(v)) return count_files(v, arr, is_folder)
    return 1
  }))
}

function sum_files (folder, arr, is_folder) {
  if (folder.size) return folder.size
  const children = arr.filter(v => v.parent === folder.id)
  return folder.size = sum(children.map(v => {
    if (is_folder(v)) return sum_files(v, arr, is_folder)
    return v.size
  }))
}

function sum (arr) {
  let result = 0
  for (const v of arr) {
    result += Number(v) || 0
  }
  return result
}

function format_size (n) {
  n = Number(n)
  if (Number.isNaN(n)) return ''
  if (n < 0) return 'invalid size'
  const units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  let flag = 0
  while (n >= 1024) {
    n = n / 1024
    flag++
  }
  return n.toFixed(2) + ' ' + units[flag]
}
