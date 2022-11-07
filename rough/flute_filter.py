import panflute


def keep_attributes_markdown(elem, doc, format="commonmark"):
    """Keep custom attributes specified in code block headers when exporting to Markdown"""
    if type(elem) == panflute.CodeBlock:
        language = "." + elem.classes[0]
        attributes = ""
        attributes = " ".join(
            [key + "=" + value for key, value in elem.attributes.items()]
        )
        header = "``` { " + " ".join([language, attributes]).strip() + " }"
        panflute.debug(header)

        code = elem.text.strip()

        footer = "```"

        content = [
            panflute.RawBlock(header, format=format),
            panflute.RawBlock(code, format=format),
            panflute.RawBlock(footer, format=format),
        ]
        return content


def main(doc=None):
    return panflute.run_filter(keep_attributes_markdown, doc=doc)


if __name__ == "__main__":
    main()