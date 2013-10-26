
INSERT into diffs (SELECT id, ST_AREA(ST_difference(st_makevalid(outlines), (SELECT g from ttf where ch = refs.ch)))::int from refs where outlines is not null AND (id % 64) = 23);
