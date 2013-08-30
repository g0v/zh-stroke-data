"""
run: pack unpack diff

pack:
	python pack.py pack > strokes.bin
	gzip -kf strokes.bin
	ls -l strokes.bin*

unpack:
	gzip -dc < strokes.bin.gz | python pack.py unpack > strokes.unpacked

diff:
	python pack.py diff
"""
import os
import sys
import struct
import json

def scale(a):
    for x in a:
        assert x < 2060
    s = 2060.0 / 256
    return [int((x + s/2) / s) for x in a]
def unscale(a):
    s = 2060.0 / 256
    return [x * s for x in a]

def init():
    with file('strokes.txt', 'w') as f:
        for root, dirs, files in os.walk('json'):
            files.sort()
            for fn in files:
                path = os.path.join(root, fn)
                o = json.load(file(path))
                ch = fn.split('.')[0]
                f.write(ch + '\t' + json.dumps(o, ensure_ascii=False) + '\n')


def pack():
    for line in file('strokes.txt'):
        k, j = line.split('\t')
        o = json.loads(j)

        assert len(o) < 256
        sys.stdout.write(struct.pack('i', int(k, 16)))
        sys.stdout.write(struct.pack('B', len(o)))
        for stroke in o:
            
            # outline
            assert len(stroke['outline']) < 256
            sys.stdout.write(struct.pack('B', len(stroke['outline'])))
            types = []
            points = []

            xs = []
            ys = []
            for outline in stroke['outline']:
                t = outline['type']
                types.append(t)
                if t == 'M':
                    xs.append(outline['x'])
                    ys.append(outline['y'])
                elif t == 'Q':
                    xs.append(outline['begin']['x'])
                    ys.append(outline['begin']['y'])
                    xs.append(outline['end']['x'])
                    ys.append(outline['end']['y'])
                elif t == 'L':
                    xs.append(outline['x'])
                    ys.append(outline['y'])
                elif t == 'C':
                    xs.append(outline['begin']['x'])
                    ys.append(outline['begin']['y'])
                    xs.append(outline['mid']['x'])
                    ys.append(outline['mid']['y'])
                    xs.append(outline['end']['x'])
                    ys.append(outline['end']['y'])
                else:
                    assert 0, 'unknown type: ' + t

            sys.stdout.write(''.join(types))
            xs = scale(xs)
            ys = scale(ys)
            sys.stdout.write(struct.pack('B'*len(xs), *xs))
            sys.stdout.write(struct.pack('B'*len(ys), *ys))
            
            sys.stdout.write(struct.pack('B', len(stroke['track'])))
            with_size = []
            xs = []
            ys = []
            ss = []
            assert len(stroke['track']) < 256
            for i, track in enumerate(stroke['track']):
                if 'size' in track:
                    with_size.append(i)
                    xs.append(track['x'])
                    ys.append(track['y'])
                    ss.append(track['size'])
                else:
                    xs.append(track['x'])
                    ys.append(track['y'])
            xs = scale(xs)
            ys = scale(ys)
            ss = scale(ss)
            sys.stdout.write(struct.pack('B', len(with_size)))
            sys.stdout.write(struct.pack('B'*len(with_size), *with_size))
            sys.stdout.write(struct.pack('B'*len(xs), *xs))
            sys.stdout.write(struct.pack('B'*len(xs), *ys))
            sys.stdout.write(struct.pack('B'*len(ss), *ss))

def unpack():
    while True:
        b = sys.stdin.read(4)
        if not b:
            break
        ch = struct.unpack('i', b)[0]

        nstroke = struct.unpack('B', sys.stdin.read(1))[0]
        o = []
        for i in range(nstroke):
            stroke = {}
            noutline = struct.unpack('B', sys.stdin.read(1))[0]

            types = sys.stdin.read(noutline)
            nm = types.count('M')
            nq = types.count('Q')
            nl = types.count('L')
            nc = types.count('C')
            npoints = nm+nq*2+nl+nc*3

            xs = list(struct.unpack('B'*npoints, sys.stdin.read(npoints * 1))) # xs
            ys = list(struct.unpack('B'*npoints, sys.stdin.read(npoints * 1))) # ys
            xs = unscale(xs)
            ys = unscale(ys)

            stroke['outline'] = []
            for t in types:
                if t == 'M':
                    outline = {'x': xs.pop(0), 'y': ys.pop(0)}
                elif t == 'Q':
                    b = {'x': xs.pop(0), 'y': ys.pop(0)}
                    e = {'x': xs.pop(0), 'y': ys.pop(0)}
                    outline = {'begin': b, 'end': e}
                elif t == 'L':
                    outline = {'x': xs.pop(0), 'y': ys.pop(0)}
                elif t == 'C':
                    b = {'x': xs.pop(0), 'y': ys.pop(0)}
                    m = {'x': xs.pop(0), 'y': ys.pop(0)}
                    e = {'x': xs.pop(0), 'y': ys.pop(0)}
                    outline = {'begin': b, 'mid': m, 'end': e}
                else:
                    assert 0
                outline['type'] = t

                stroke['outline'].append(outline)


            ntrack = struct.unpack('B', sys.stdin.read(1))[0]
            nwith_size = struct.unpack('B', sys.stdin.read(1))[0]
            with_size = struct.unpack('B'*nwith_size, sys.stdin.read(nwith_size * 1)) # with_size
            xs = list(struct.unpack('B'*ntrack, (sys.stdin.read(ntrack * 1)))) # xs
            ys = list(struct.unpack('B'*ntrack, (sys.stdin.read(ntrack * 1)))) # ys
            ss = list(struct.unpack('B'*nwith_size, (sys.stdin.read(nwith_size * 1)))) # ss
            xs = unscale(xs)
            ys = unscale(ys)
            ss = unscale(ss)

            stroke['track'] = []
            for i in range(ntrack):
                if i in with_size:
                    track = {'x':xs.pop(0), 'y':ys.pop(0), 'size':ss.pop(0)}
                else:
                    track = {'x':xs.pop(0), 'y':ys.pop(0)}
                stroke['track'].append(track)

            o.append(stroke)

        sys.stdout.write('%x\t%s\n' % (ch, json.dumps(o, ensure_ascii=False)))

def calculate_diff(a, b):
    ta = type(a)
    tb = type(b)
    if ta is int or ta is float:
        assert tb is int or tb is float
    else:
        assert ta == tb, '%s, %s' % (ta, tb)

    d = 0
    if ta is list:
        assert len(a) == len(b)
        for i in range(len(a)):
            d = max(d, calculate_diff(a[i], b[i]))
    elif ta is dict:
        if len(a) != len(b):
            print a
            print b
            assert 0
        for k in a:
            va = a[k]
            vb = b[k]
            d = max(d, calculate_diff(va, vb))
    elif ta is int or ta is float:
        return abs(a - b)
    elif ta is unicode:
        assert a == b
        return 0
    else:
        assert 0, 'unknown type %s' % ta

    return d

def diff():
    lines_a = file('strokes.txt').readlines()
    lines_b = file('strokes.unpacked').readlines()
    assert len(lines_a) == len(lines_b)

    md = 0
    for i in range(len(lines_a)):
        ca, ja = lines_a[i].split('\t')
        cb, jb = lines_b[i].split('\t')

        assert ca == cb

        d = calculate_diff(json.loads(ja), json.loads(jb))
        md = max(d, md)
        if d > 10:
            print ja
            print jb
            print d
            break

    print 'max diff', md

    


def main():
    cmd = sys.argv[1]
    if cmd == 'init':
        init()
    elif cmd == 'pack':
        pack()
    elif cmd == 'unpack':
        unpack()
    elif cmd == 'diff':
        diff()
    else:
        assert 0


if __name__ == '__main__':
    main()
