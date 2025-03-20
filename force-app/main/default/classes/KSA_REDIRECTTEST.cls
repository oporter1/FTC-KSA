@isTest
public class KSA_REDIRECTTEST {
    public PageReference hello1() {
        PageReference reference=new PageReference('http://www.ksaevents.net');
        reference.setRedirect(true);
        return reference;
    }
}