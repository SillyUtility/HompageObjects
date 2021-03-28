function buildItem(item) {
    let sources = item.layouts.concat(item.source)
    let template = new Template(sources)
    item.rendered = template(item.args)
}
