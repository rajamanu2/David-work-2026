public class Ratings {

    // SOQL fixed
    // TODO: hardcoded Custom Field IDs need to be replaced
    ProductItem__c p;
    String cosmetic, functional, rating, Name, completed, ratingtype;
    String pitemId;
    id userid;
    public Ratings(ApexPages.StandardController controller) {
        UserID = UserInfo.getUserId();
        // this is for Sandbox 
        // pitemId = ApexPages.currentPage().getParameters().get('CF00NW0000001nGHy_lkid');

        // this is for Production 
        pitemId = ApexPages.currentPage().getParameters().get('CF00N0B0000066uAE_lkid');

        p = [Select id, Cosmetic_Rating__c, Functional_Rating__c,Name from ProductItem__c where Id = :pitemId];
        Cosmetic = p.Cosmetic_Rating__c;
        Functional = p.Functional_Rating__c;
        Name = p.Name;

        // Using the UserInfo class instead of SOQL
/*
        User UserName = [select id, name, FirstName, LastName, profileID from User where id=:userid];
        Completed = username.FirstName + ' ' + username.LastName;
         Name=p.Name;
*/
        Completed = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

    }

    public PageReference newCosmeticRating() {
        rating = cosmetic;
        ratingtype = 'Cosmetic Rating';
        system.debug('THIS IS THE RATING >>> ' + rating);
        // this is for Sandbox
        // PageReference pr = new PageReference('/a0A/e?&CF00NW0000001nGHy_lkid='+pitemId+'&retURL='+pitemId+'&CF00NW0000001nGHy='+Name+'&00NW0000001nGGH=' + Rating + '&00NW0000001nGGR=' + Completed + '&00NW0000001nGHo=' + ratingtype);

        // this is for Production
        PageReference pr = new PageReference('/a0A/e?&CF00N0B0000066uAE_lkid=' + pitemId + '&retURL=' + pitemId + '&CF00N0B0000066uAE=' + Name + '&00N0B0000066uAJ=' + Rating + '&00N0B0000066uAY=' + Completed + '&00N0B0000066uAT=' + ratingtype);


        pr.getParameters().put('nooverride', '1');
        pr.setRedirect(false);
        return pr;
    }
    public PageReference newFunctionalRating() {
        rating = functional;
        ratingtype = 'Functional Rating';
        // this is for Sandbox
        // PageReference pr = new PageReference('/a0A/e?&CF00NW0000001nGHy_lkid='+pitemId+'&retURL='+pitemId+'&CF00NW0000001nGHy='+Name+'&00NW0000001nGGH=' + Rating + '&00NW0000001nGGR=' + Completed + '&00NW0000001nGHo=' + ratingtype);

        // this is for Production
        PageReference pr = new PageReference('/a0A/e?&CF00N0B0000066uAE_lkid=' + pitemId + '&retURL=' + pitemId + '&CF00N0B0000066uAE=' + Name + '&00N0B0000066uAJ=' + Rating + '&00N0B0000066uAY=' + Completed + '&00N0B0000066uAT=' + ratingtype);


        pr.getParameters().put('nooverride', '1');
        pr.setRedirect(false);
        return pr;
    }

}