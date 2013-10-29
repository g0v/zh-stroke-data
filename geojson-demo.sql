select st_asgeojson(st_rotate(ST_FlipCoordinates(
    st_collect(
        st_translate(st_scale(st_collect(outlines), 0.001, 0.001), 21.2416976, 121.4509512),
        st_translate(st_scale(st_collect(tracks), 0.001, 0.001), 24.4416976, 121.4509512)
    )
),pi()/2*3,121.4509512,24.4416976)) from strokes where ch = '萌';
