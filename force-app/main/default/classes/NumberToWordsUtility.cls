public class NumberToWordsUtility 
{ 
    private static final Map<Integer, String> basicWords = new Map<Integer, String> { 
        	0 => 'zero', 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four', 5 => 'five', 
            6 => 'six', 7 => 'seven', 8 => 'eight', 9 => 'nine', 10 => 'ten', 
            11 => 'eleven', 12 => 'twelve', 13 => 'thirteen', 14 => 'fourteen', 
            15 => 'fifteen', 16 => 'sixteen', 17 => 'seventeen', 18 => 'eighteen', 19 => 'nineteen' }; 
    private static final Map<Integer, String> tensWords = new Map<Integer, String> { 
       		20 => 'twenty', 30 => 'thirty', 40 => 'forty', 50 => 'fifty', 60 => 'sixty', 
            70 => 'seventy', 80 => 'eighty', 90 => 'ninety' }; 
    public static void toWords(Integer inputNumber) { 
                if (inputNumber == null || inputNumber < 0 || inputNumber > 9999999) { 
                    System.debug('Invalid input: Enter a number between 0 and 99,99,999'); 
                    return; 
                } 
                if (inputNumber == 0) { 
                    System.debug('zero'); 
                    return; 
                } 
                List<String> parts = new List<String>(); 
                Integer remaining = inputNumber; 
                Integer crore = remaining / 10000000; 
                remaining = Math.mod(remaining, 10000000); 
                Integer lakh = remaining / 100000; 
                remaining = Math.mod(remaining, 100000); 
                Integer thousand = remaining / 1000; 
                remaining = Math.mod(remaining, 1000); 
                Integer hundred = remaining / 100; 
                remaining = Math.mod(remaining, 100); 
                Integer lastTwo = remaining; 
                if (crore > 0) { 
                    parts.add(convertTwoDigit(crore) + ' crore'); 
                } 
                if (lakh > 0) { 
                    parts.add(convertTwoDigit(lakh) + ' lakh'); 
                } 
                if (thousand > 0) { 
                    parts.add(convertTwoDigit(thousand) + ' thousand'); 
                } 
                if (hundred > 0) { 
                    parts.add(basicWords.get(hundred) + ' hundred'); 
                } 
                if (lastTwo > 0) { 
                    parts.add(convertTwoDigit(lastTwo)); 
                } 
                String finalOutput = ''; 
                for (String segment : parts) { 
                    finalOutput += segment + ' '; 
                } 
                System.debug(inputNumber +' in Words: ' + finalOutput.trim()); 
            } 
    private static String convertTwoDigit(Integer value) { 
        if (value < 20) { 
            return basicWords.get(value); 
        } else { 
            Integer tens = (value / 10) * 10; 
            Integer units = Math.mod(value, 10); 
            String result = tensWords.get(tens); 
            if (units > 0) { 
                result += ' ' + basicWords.get(units); 
            } 
            return result; 
        } 
    } 
}