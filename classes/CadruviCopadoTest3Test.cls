@isTest
private class CadruviCopadoTest3Test {
    @isTest static void myTest() {
        CadruviCopadoTest3 myobj = new CadruviCopadoTest3();
        Integer retVal = myobj.myMethod();
        System.assert(retVal == 3);
    }
}