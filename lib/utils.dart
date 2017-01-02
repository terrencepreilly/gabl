
/// A stream object which allows forward peeking by one.
class SimpleStream<T> {
    int curr;
    List<T> contents;

    SimpleStream(this.contents) :
        this.curr = 0;

    SimpleStream.from(Iterable<T> iter) {
        this.contents = new List<T>.from(iter);
        this.curr = 0;
    }

    T peek() {
        return contents[curr];
    }

    T next() {
        return contents[curr++];
    }

    bool hasNext() {
        return curr < contents.length;
    }

    T nextWhich(Function f) {
        while (!f(this.peek()) && this.hasNext())
            this.next();
    }

    void push(T t) {
        this.contents.add(t);
    }

    T pop() {
        this.contents.removeLast();
    }
}

/// An AST Node.
class Node {
    String type;
    String value;
    List<Node> children;

    Node({this.type, this.value})
        : children = new List<Node>();

    addChild(Node n) {
        children.add(n);
    }

    childAt(int i) {
        return children[i];
    }

    String toString() {
        int half = children.length ~/ 2;
        String ret = '(';
        ret += children.getRange(0, half).join(' ');
        if (half > 0) {
            if (value != '')
                ret += ' ' + value + ' ';
            else if (type == 'block'
                    || type == 'parameters')
                ret += ' ';
        } else {
            ret += value;
        }
        ret += children.getRange(half, children.length).join(' ');
        ret += ')';
        return ret;
    }
}
