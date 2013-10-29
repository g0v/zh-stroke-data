DROP TABLE distances;
CREATE table distances ( id int, distance int );
CREATE index distances_id on distances (id);
/*
INSERT INTO distances (
    SELECT id, ST_HausdorffDistance( st_makebox2d(st_makepoint(x, y), st_makepoint(x+w, y+h)), box2d(outlines)) FROM refs ORDER BY id
);
*/
INSERT INTO distances (
    SELECT id, sqrt((abs(
        (ST_XMax(box2d(outlines)) - ST_XMin(box2d(outlines))) - w
    )+1) * (abs(
        (ST_YMax(box2d(outlines)) - ST_YMin(box2d(outlines))) - h
    )+1)) FROM refs ORDER BY id
);
