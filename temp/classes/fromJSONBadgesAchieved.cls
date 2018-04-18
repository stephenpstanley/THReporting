public class fromJSONBadgesAchieved{
	public Long total_count;	//2
	public cls_data[] data;
	public class cls_data {
		public String id;	//4283991
		public DateTime created_at;	//2015-10-26T15:02:23.000Z
		public DateTime updated_at;	//2018-02-15T14:51:24.051Z
		public string username ;
		public String email;	//tmarkussen@salesforce.com
		public String profile_url;	//https://trailhead.salesforce.com/users/profiles/005500000060kNwAAI
		public cls_salesforce_ids[] salesforce_ids;
		public String first_name;	//Torben
		public String last_name;	//Markussen
		public String avatar;	//https://developer.salesforce.com/forums/profilephoto/729F0000000HvoP/F
		public String company;	//Salesforce
		public String postal_code;	//
		public String rank;	//Ranger
		public Long total_points;	//224251
		public String country;	//DK
		public cls_badges badges;
		public cls_modules[] modules;
		public cls_projects[] projects;
		public cls_superbadges[] superbadges;
		public String profile_visibility;	//public
		public cls_user_trailmixes[] user_trailmixes;
	}

	class cls_salesforce_ids {
		public String org_id;	//00D000000000062EAA
		public String user_id;	//0053000000BzgFlAAJ
	}
	public class cls_badges {
		public cls_peer_assesment_badges[] peer_assesment_badges;
	}
	public class cls_peer_assesment_badges {
        public String id;
        public String badge_title;
        public String api_name;
        public String badge_icon;
        public String message;
        public String xabstract;  //This may need fixing once it actually holds any data
        public DateTime finished_at;
        public DateTime created_at;
        public DateTime updated_at;
	}
	class cls_modules {
		public String id;	//2010
		public String title;	//Customer Usage Data
		public boolean completed;
		public String status;	//Completed
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/modules/trailhead_module_customer_usage_data.png
		public String badge_title;	//Customer Usage Data
		public DateTime first_attempted_at;	//2017-04-08T14:34:38.497Z
		public DateTime last_attempted_at;	//2017-04-08T15:02:38.660Z
		public DateTime finished_at;	//2017-04-08T15:02:38.941Z
		public String type;	//Th::Module
		public boolean archived;
		public String web_url;	//https://developer.salesforce.com/trailhead/module/mr-customer-usage-data-in-selling
	}
	class cls_projects {
		public String id;	//1107
		public String title;	//Create a Satisfaction Survey
		public boolean completed;
		public String status;	//Completed
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/projects/trailhead_project_create_a_satisfaction_survey.png
		public String badge_title;	//Create a Satisfaction Survey
		public DateTime first_attempted_at;	//2016-12-03T18:57:05.954Z
		public DateTime last_attempted_at;	//2016-12-03T20:35:32.565Z
		public DateTime finished_at;	//2016-12-03T20:35:33.822Z
		public String type;	//Th::Project
		public boolean archived;
		public String web_url;	//https://developer.salesforce.com/trailhead/project/flow_satisfaction
	}
	class cls_superbadges {
		public String id;	//2393
		public DateTime created_at;	//2018-01-14T14:55:03.850Z
		public DateTime updated_at;	//2018-01-14T14:55:03.872Z
		public String title;	//Reports & Dashboards Specialist
		public String description;	//Craft a set of powerful reports and dashboards to shine a light on your data.
		public String duration;	//4-6 Hours
		public String ascent_badge_url;	//https://developer.salesforce.com/resource/images/trailhead/badges/superbadges/trailhead_superbadge_reports_dashboards_flag.png
		public Long completion_points;	//2000
		public Long first_ascent_points;	//2000
		public cls_prerequisites[] prerequisites;
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/superbadges/trailhead_superbadge_reports_dashboards.png
		public String web_url;	//https://developer.salesforce.com/trailhead/en/super_badges/superbadge_reports/
		public boolean archived;
		public String status;	//In-Progress
		public DateTime first_attempted_at;	//2018-01-14T14:55:03.850Z
		public DateTime last_attempted_at;	//2018-01-14T14:55:05.152Z
		public DateTime finished_at;
	}
	class cls_prerequisites {
		public String id;	//275
		public DateTime created_at;	//2016-06-30T18:22:49.022Z
		public DateTime updated_at;	//2017-07-25T17:23:56.908Z
		public String title;	//Data Management
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/modules/trailhead_module_lightning_data_management.png
		public String description_html;	//Learn how to import and export data in Salesforce.
		public String badge_title;	//Data Management
		public String web_url;	//https://developer.salesforce.com/trailhead/module/lex_implementation_data_management/
		public boolean archived;
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
		public cls_units[] units;
	}
	class cls_tags {
		public String id;	//6
		public String title;	//Data Management
	}
	class cls_roles {
		public String id;	//28
		public String title;	//Admin
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
		public String id;	//25607
		public DateTime created_at;	//2018-02-14T19:46:31.281Z
		public DateTime updated_at;	//2018-02-14T19:57:11.758Z
		public String title;	//Import Data
		public String description_html;	//You can easily import data into Salesforce from an existing data source, using the
		public String built_date;	//2018-02-14T00:00:53.000Z
		public String web_url;	//https://developer.salesforce.com/trailhead/lex_implementation_data_management/lex_implementation_data_import/
		public Long challenge_time;	//30
		public Integer total_points;	//500
		public boolean archived;
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
	}
	class cls_user_trailmixes {
	}
	public static fromJSONBadgesAchieved parse(String json){
		return (fromJSONBadgesAchieved) System.JSON.deserialize(json, fromJSONBadgesAchieved.class);
	}
}