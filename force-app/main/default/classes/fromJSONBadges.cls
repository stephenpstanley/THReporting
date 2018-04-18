public class fromJSONBadges{
	public Integer total_count;	//8
	public cls_data data;
    
	public class cls_data {
		public cls_peer_assesment_badges[] peer_assesment_badges;
	}
	public class cls_peer_assesment_badges {
		public String id;	//615
		public String api_name;	//salesforce_corp_message_cert_2018
		public String badge_icon;	//https://s3.amazonaws.com/dfc-data-production/files/PeerAsessmentBadges/trailhead_peer_assess_corp.png
		public String badge_title;	//Corporate Message Certification
		public String message;	//Wahoo!
//		public String abstract;	//As #OneOhana it's important for us to position Salesforce in the same way, across every department and role. This badge will light up when you pass the group corporate message certification session.
		public Datetime created_at;	//2017-12-15T18:45:22.118Z
		public Datetime updated_at;	//2017-12-16T00:59:51.946Z
	}
	public static fromJSONBadges parse(String json){
		return (fromJSONBadges) System.JSON.deserialize(json, fromJSONBadges.class);
	}
}