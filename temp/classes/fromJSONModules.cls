public class fromJSONModules{
	public Integer total_count;	//493
	public cls_data[] data;
	class cls_data {
		public String id;	//1350
		public DateTime created_at;	//2016-09-30T20:11:20.592Z
		public DateTime updated_at;	//2017-11-03T01:26:07.423Z
		public String title;	//Marketing Cloud Products
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/modules/trailhead_module_marketing_cloud_studios_and_builders.png
		public String description_html;	//Connect with the right person, the right way, at the right time with Marketing Cloud.
		public String badge_title;	//Marketing Cloud Studios & Builders
		public String web_url;	//https://developer.salesforce.com/trailhead/module/mrkt_cloud_studios_builders/
		public boolean archived;
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
		public cls_units[] units;
	}
	class cls_tags {
		public String id;	//25
		public String title;	//General
	}
	class cls_roles {
		public String id;	//27
		public String title;	//Business User
	}
	class cls_products {
		public String id;	//33
		public String title;	//Marketing Cloud
	}
	class cls_levels {
		public String id;	//42
		public String title;	//Beginner
	}
	class cls_units {
		public String id;	//26750
		public DateTime created_at;	//2018-02-14T19:53:11.180Z
		public DateTime updated_at;	//2018-02-14T19:53:14.674Z
		public String title;	//Learn About Our Marketing Cloud Messaging Products
		public String description_html;
		public DateTime built_date;
		public String web_url;	//https://developer.salesforce.com/trailhead/mrkt_cloud_studios_builders/mrkt_cloud_studios_builders_learn_studios/
		public Integer challenge_time;	//20
		public Integer total_points;	//100
		public boolean archived;
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
    }

	public static fromJSONModules parse(String json){
		return (fromJSONModules) System.JSON.deserialize(json, fromJSONModules.class);
	}
}