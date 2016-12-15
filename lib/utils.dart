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
