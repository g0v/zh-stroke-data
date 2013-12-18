/**
 * parson.h and parson.c come from:
 * https://github.com/kgabis/parson
 */
#include <stdio.h>
#include <assert.h>
#include "parson.h"

int main(int argc, char **argv) {
    JSON_Value *root;
    JSON_Array *strokes, *track;
    JSON_Object *stroke, *point;
    size_t i, j;

    root = json_parse_file("../data/json/840c.json");
    assert(json_value_get_type(root) == JSONArray);

    strokes = json_value_get_array(root);
    for (i = 0; i < json_array_get_count(strokes); ++i) {
        stroke = json_array_get_object(strokes, i);
        track = json_object_get_array(stroke, "track");
        for (j = 0; j < json_array_get_count(track); ++j) {
            point = json_array_get_object(track, j);
            printf("(%lf, %lf)\n",
                json_object_get_number(point, "x"),
                json_object_get_number(point, "y")
            );
        }
        printf("\n");
    }

    return 0;
}
