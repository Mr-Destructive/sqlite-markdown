#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1
#include <stdlib.h>
#include <string.h>
#include "cmark.h"

/*
 * markdown(text)
 * Returns the HTML representation of the markdown text.
 */
static void markdown_func(
    sqlite3_context *context,
    int argc,
    sqlite3_value **argv
) {
    if (argc != 1) {
        sqlite3_result_error(context, "markdown() takes exactly one argument", -1);
        return;
    }

    if (sqlite3_value_type(argv[0]) == SQLITE_NULL) {
        sqlite3_result_null(context);
        return;
    }

    const char *input_text = (const char *)sqlite3_value_text(argv[0]);
    if (input_text == NULL) {
        sqlite3_result_null(context);
        return;
    }

    // Parse and render
    // CMARK_OPT_DEFAULT is 0. 
    // You can add CMARK_OPT_SAFE to filter HTML, or CMARK_OPT_VALIDATE_UTF8
    // For GFM extensions in cmark-gfm, we'd need to register them.
    // For standard cmark, this provides CommonMark compliance.
    
    // Using cmark_markdown_to_html is the simplest API
    char *html_output = cmark_markdown_to_html(input_text, strlen(input_text), CMARK_OPT_DEFAULT);

    if (html_output) {
        sqlite3_result_text(context, html_output, -1, SQLITE_TRANSIENT);
        free(html_output); // cmark allocates with malloc/calloc
    } else {
        sqlite3_result_error_nomem(context);
    }
}

#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_markdown_init(
    sqlite3 *db, 
    char **pzErrMsg, 
    const sqlite3_api_routines *pApi
) {
    int rc = SQLITE_OK;
    SQLITE_EXTENSION_INIT2(pApi);

    rc = sqlite3_create_function(
        db, 
        "markdown", 
        1, 
        SQLITE_UTF8 | SQLITE_DETERMINISTIC, 
        0, 
        markdown_func, 
        0, 
        0
    );

    return rc;
}
