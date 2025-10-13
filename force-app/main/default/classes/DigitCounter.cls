public class DigitCounter {
    public static void countDigits(Integer inputNumber) {
        String numStr = String.valueOf(inputNumber);   // typecast number to string
        System.debug('Input as string: ' + numStr);
        Map<Integer, Integer> digitMap = new Map<Integer, Integer>();        // Map to store digit counts
        // Count each digit
        for (Integer i = 0; i < numStr.length(); i++) {
            Integer digit = Integer.valueOf(numStr.substring(i, i + 1)); //extracting string_digit using substring -> int
            if (digitMap.containsKey(digit)) {
                digitMap.put(digit, digitMap.get(digit) + 1); // if present -> increment
            } else {
                digitMap.put(digit, 1);// if no -> add in map as 1st occurence
            }
        }
        for (Integer d = 0; d <= 9; d++) {        // Print digits from 0 to 9 if they exist in the map
            if (digitMap.containsKey(d)) {
                System.debug('Occurance of ' + d + ' : ' + digitMap.get(d));
            }
        }//DigitCounter.countDigits(---Enter number here---);
    }
}