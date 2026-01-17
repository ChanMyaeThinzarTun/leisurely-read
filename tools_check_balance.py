from collections import deque
pairs = {'(':')','[':']','{':'}'}
openers = set(pairs.keys())
closers = set(pairs.values())
stack = deque()
with open('lib/screens/writer_home.dart','r',encoding='utf-8') as f:
    for i,line in enumerate(f, start=1):
        for j,ch in enumerate(line, start=1):
            if ch in openers:
                stack.append((ch,i,j))
            elif ch in closers:
                if not stack:
                    print(f"Unmatched closer {ch} at {i}:{j}")
                    raise SystemExit(1)
                last,li,lj = stack.pop()
                if pairs[last] != ch:
                    print(f"Mismatched {last} (opened at {li}:{lj}) closed by {ch} at {i}:{j}")
                    raise SystemExit(1)
if stack:
    for ch,i,j in stack:
        print(f"Unclosed opener {ch} at {i}:{j}")
else:
    print('All balanced')
