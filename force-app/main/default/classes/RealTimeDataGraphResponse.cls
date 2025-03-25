public with sharing class RealTimeDataGraphResponse {
    public List<DataItem> data { get; set; }
    public Boolean done { get; set; }

    public class DataItem {
        public String json_blob { get; set; }
    }

    public class JsonBlob {
        public String Id { get; set; }
        public String CreatedDate { get; set; }
        public String FirstName { get; set; }
        public String LastName { get; set; }
        public String IsAnonymous { get; set; }
        public List<UnifiedLink> UnifiedLinkssotIndividualI1 { get; set; }
    }

    public class UnifiedLink {
        public String SourceRecordId { get; set; }
        public String UnifiedRecordId { get; set; }
        public List<Individual> Individual { get; set; }
    }

    public class Individual {
        public String DataSourceId { get; set; }
        public String FirstName { get; set; }
        public String Id { get; set; }
        public String LastName { get; set; }
        public String IsAnonymous { get; set; }
        public List<ContactPointEmail> ContactPointEmail { get; set; }
        public List<ProductBrowseEngagement> ProductBrowseEngagement { get; set; }
        public List<ShoppingCartEngagement> ShoppingCartEngagement { get; set; }
    }

    public class ContactPointEmail {
        public String Id { get; set; }
        public String PartyId { get; set; }
        public String CreatedDate { get; set; }
        public String DataSourceId { get; set; }
        public String EmailAddress { get; set; }
    }

    public class ProductBrowseEngagement implements Comparable {
        public String IndividualId { get; set; }
        public String CreatedDate { get; set; }
        public String EngagementChannelActionId { get; set; }
        public String EngagementTypeId { get; set; }
        public String Id { get; set; }
        public String ProductId { get; set; }
        public String EngagementChannelId { get; set; }
        public String Name { get; set; }

        public Integer compareTo(Object compareToObj) {
            ProductBrowseEngagement other = (ProductBrowseEngagement)compareToObj;
            
            // Parse ISO 8601 dates using JSON deserialization
            Datetime thisDate = (Datetime)JSON.deserialize('"' + this.CreatedDate + '"', Datetime.class);
            Datetime otherDate = (Datetime)JSON.deserialize('"' + other.CreatedDate + '"', Datetime.class);
            
            Long thisMillis = thisDate.getTime();
            Long otherMillis = otherDate.getTime();
            
            if (thisMillis > otherMillis) return -1;
            if (thisMillis < otherMillis) return 1;
            return 0;
        }
    }

    public class ShoppingCartEngagement implements Comparable {
        public String CreatedDate { get; set; }
        public String CurrencyId { get; set; }
        public String EngagementTypeId { get; set; }
        public String Id { get; set; }
        public String IndividualId { get; set; }
        public String ProductId { get; set; }
        public Decimal ProductPriceAmount { get; set; }
        public Decimal ProductQuantity { get; set; }

        public Integer compareTo(Object compareToObj) {
            ShoppingCartEngagement other = (ShoppingCartEngagement)compareToObj;
            Datetime thisDate = (Datetime)JSON.deserialize('"' + this.CreatedDate + '"', Datetime.class);
            Datetime otherDate = (Datetime)JSON.deserialize('"' + other.CreatedDate + '"', Datetime.class);
            
            Long thisMillis = thisDate.getTime();
            Long otherMillis = otherDate.getTime();
            
            if (thisMillis > otherMillis) return -1;
            if (thisMillis < otherMillis) return 1;
            return 0;
        }
    }

    public static RealTimeDataGraphResponse parse(String json) {
        return (RealTimeDataGraphResponse) System.JSON.deserialize(json, RealTimeDataGraphResponse.class);
    }
}