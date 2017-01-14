
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

    void addChild(Node n) {
        children.add(n);
    }

    Node childAt(int i) {
        return children[i];
    }

    /// Return the [i]th child, and all after.
    List<Node> childrenAfter(int i) {
        if (i >= children.length)
            return new List<Node>();
        return children.sublist(i);
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

    String _toDotDefinition([String identifier="0"]) {
        String safe_value = value;
        if (['<-', '<', '>'].contains(safe_value))
            safe_value = '';
        String self = [
            '\tnode_$identifier [shape=none, margin=0, label=<',
            '\t    <table border="0" cellborder="1"',
            '\t          cellspacing="0" cellpadding="4">',
            '\t     <tr>',
            '\t       <td>$type</td>',
            '\t       <td>"$safe_value"</td>',
            '\t     </tr>',
            '\t   </table>',
            '\t>];\n\n'].join('\n');
        for (int i = 0; i < children.length; i++) {
            self += children[i]._toDotDefinition(identifier + i.toString());
        }
        return self;
    }

    String _toDotRelationship([String identifier="0"]) {
        String self = '';
        for (int i = 0; i < children.length; i++) {
            self += '\tnode_$identifier -> node_${identifier + i.toString()};\n';
        }
        for (int i = 0; i < children.length; i++) {
            self += children[i]._toDotRelationship(identifier + i.toString());
        }
        return self;
    }

    String graph() {
        return [
            'digraph G {',
            '${this._toDotDefinition()}',
            '${this._toDotRelationship()}',
            '}'].join('\n');
    }
}
