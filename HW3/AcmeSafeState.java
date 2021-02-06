import java.util.concurrent.atomic.AtomicLongArray;

class AcmeSafeState implements State {
    private AtomicLongArray value;

    AcmeSafeState(int length) { value = new AtomicLongArray(length); }

    public int size() { return value.length(); }

    public long[] current() { 
        int size = this.size();
        long[] value = new long[size];
        for (int i = 0; i < size; i++) {
            value[i] = this.value.get(i);
        }
        return value;
     }

    public void swap(int i, int j) {
        value.getAndDecrement(i);
        value.getAndIncrement(j);
    }
}
