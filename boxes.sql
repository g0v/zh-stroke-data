create table boxes (ch text, minx int, miny int, w int, h int, box box2d);
create index boxes_ch on boxes (ch);
insert into boxes (select ch, null, null, box2d(st_collect(outlines)) from strokes);
update boxes set minx = st_xmin(box);
update boxes set miny = st_ymin(box);
update boxes set w = st_xmax(box) - st_xmin(box);
update boxes set h = st_ymax(box) - st_ymin(box);
