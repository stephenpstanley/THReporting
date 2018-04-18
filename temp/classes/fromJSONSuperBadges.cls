public class fromJSONSuperBadges{
	public Integer total_count;	//10
	public cls_data[] data;
	class cls_data {
		public String id;	//2373
		public DateTime created_at;	//2016-06-05T17:30:29.731Z
		public DateTime updated_at;	//2018-02-14T19:56:12.879Z
		public String title;	//Apex Specialist
		public String description;	//Use integration and business logic to push your Apex coding skills to the limit.
		public String duration;	//8-12 Hours
		public String ascent_badge_url;	//https://developer.salesforce.com/resource/images/trailhead/badges/superbadges/trailhead_superbadge_apex_flag.png
		public Integer completion_points;	//2000
		public Integer first_ascent_points;	//2000
		public cls_prerequisites[] prerequisites;
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/superbadges/trailhead_superbadge_apex.png
		public String web_url;	//https://developer.salesforce.com/trailhead/en/super_badges/superbadge_apex/
		public boolean archived;
	}
	class cls_prerequisites {
		public String id;	//682
		public DateTime created_at;	//2016-07-13T16:44:25.058Z
		public DateTime updated_at;	//2017-06-17T00:47:36.489Z
		public String title;	//Apex Triggers
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/modules/trailhead_module_apex_triggers.png
		public String description_html;	//Write Apex triggers to perform custom database actions.
		public String badge_title;	//Apex Triggers
		public String web_url;	//https://developer.salesforce.com/trailhead/module/apex_triggers/
		public boolean archived;
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
		public cls_units[] units;
	}
	class cls_tags {
		public String id;	//1
		public String title;	//Apex
	}
	class cls_roles {
		public String id;	//29
		public String title;	//Developer
	}
	class cls_products {
		public String id;	//35
		public String title;	//Salesforce Platform
	}
	class cls_levels {
		public String id;	//42
		public String title;	//Beginner
	}
	class cls_units {
		public String id;	//25705
		public DateTime created_at;	//2018-02-14T19:47:13.561Z
		public DateTime updated_at;	//2018-02-14T19:56:16.896Z
		public String title;	//Get Started with Apex Triggers
		public String description_html;	//Apex triggers enable you to perform custom actions that you define before or after
		public String built_date;	//2018-02-14T00:06:10.000Z
		public String web_url;	//https://developer.salesforce.com/trailhead/apex_triggers/apex_triggers_intro/
		public Integer challenge_time;	//30
		public Integer total_points;	//500
		public boolean archived;
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
	}
	public static fromJSONSuperBadges parse(String json){
		return (fromJSONSuperBadges) System.JSON.deserialize(json, fromJSONSuperBadges.class);
	}
}