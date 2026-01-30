CREATE TABLE apple_discovery (
            trackId INTEGER PRIMARY KEY,
            collectionName TEXT,
            artistName TEXT,
            feedUrl TEXT,
            artworkUrl TEXT,
            primaryGenreName TEXT,
            genres TEXT,
            country TEXT,
            trackCount INTEGER,
            releaseDate TEXT,
            description TEXT,
            raw_json TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

CREATE TABLE apple_podcast_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            apple_id TEXT,
            parent_apple_id TEXT,
            name TEXT,
            full_path TEXT
        );

CREATE TABLE brand_vectors (
            adlid INTEGER PRIMARY KEY,
            embedding TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

CREATE TABLE brands (
            adlid INTEGER PRIMARY KEY AUTOINCREMENT,
            brand_name TEXT,
            website_url TEXT UNIQUE,
            source_website_raw TEXT,
            source_linkedin_raw TEXT,
            source_social_raw TEXT,
            extracted_description TEXT,
            extracted_product_category TEXT,
            extracted_target_audience TEXT,
            extracted_tone TEXT,
            extracted_key_themes TEXT,
            extracted_goals TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        , brand_vertical TEXT, brand_audience_profile TEXT, brand_use_cases TEXT, brand_pain_points TEXT, brand_geo_focus TEXT, brand_keywords TEXT, brand_summary TEXT, brand_vertical_override TEXT, flag_inconsistent_positioning INTEGER, recommended_vertical TEXT, recommended_confidence REAL, candidate_verticals TEXT, normalized_text TEXT, normalisation_version TEXT, normalized_summary TEXT, normalized_vertical TEXT, normalized_audience TEXT, normalized_pain_points TEXT, normalized_use_cases TEXT, normalized_themes TEXT, normalized_tone TEXT, normalized_geo TEXT, normalized_topics TEXT);

CREATE TABLE creator_cluster_labels (
            cluster_id INTEGER,
            vector_type TEXT,
            method TEXT,
            label TEXT,
            top_topics TEXT,
            top_keywords TEXT,
            size INTEGER,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (cluster_id, vector_type, method)
        );

CREATE TABLE creator_clusters (
            podcastindex_id INTEGER,
            cluster_id INTEGER,
            vector_type TEXT,
            model_name TEXT,
            method TEXT,
            params_json TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (podcastindex_id, vector_type, method)
        );

CREATE TABLE creator_country (
            podcastindex_id INTEGER PRIMARY KEY,
            itunesid INTEGER,
            country TEXT
        );

CREATE TABLE creator_enrichment (
            adlid INTEGER PRIMARY KEY AUTOINCREMENT,
            podcastindex_id INTEGER,
            uk_score REAL,
            source_spotify TEXT,
            source_apple TEXT,
            source_youtube TEXT,
            source_social_twitter TEXT,
            source_social_instagram TEXT,
            source_social_website TEXT,
            source_social_patreon TEXT,
            cleaned_text_block TEXT,
            raw_text_sources TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        , normalized_text TEXT);

CREATE TABLE creator_meta (
            adlid INTEGER PRIMARY KEY,
            verified_email TEXT,
            source_email TEXT,
            gemini_data TEXT,
            confidence REAL,
            model_version TEXT,
            last_lookup_at DATETIME, contact_form_url TEXT,
            FOREIGN KEY (adlid) REFERENCES creators(adlid)
        );

CREATE TABLE creator_survey_status (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            creator_survey_id INTEGER NOT NULL,
            status_code INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (creator_survey_id) REFERENCES creator_surveys(id)
        );

CREATE TABLE creator_surveys (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            creator_adlid INTEGER NOT NULL,
            podcast TEXT,
            name TEXT,
            comment TEXT,
            url TEXT,
            email TEXT NOT NULL,
            itunes TEXT,
            template TEXT,
            sent_date TEXT,
            received_date TEXT,
            response TEXT,
            survey_template_id INTEGER,
            has_duplicate INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        , response_received_at TEXT, raw_response_text TEXT);

CREATE TABLE creator_topics (
            podcastindex_id INTEGER,
            apple_category_id TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY(podcastindex_id, apple_category_id)
        );

CREATE TABLE creator_vectors (
            podcastindex_id INTEGER PRIMARY KEY,
            embedding TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

CREATE TABLE creators (
            adlid INTEGER PRIMARY KEY AUTOINCREMENT,
            podcastindex_id INTEGER,
            podcastguid TEXT,
            itunesid INTEGER,
            language TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        , vertical TEXT, audience_profile TEXT, industry_keywords TEXT, business_functions TEXT, pain_points TEXT, geo_focus TEXT, title TEXT, description TEXT, feed_url TEXT, web_link TEXT, categories TEXT, newestItemPubdate INTEGER, oldestItemPubdate INTEGER, episodeCount INTEGER, updateFrequency INTEGER, normalized_summary TEXT, normalized_vertical TEXT, normalized_audience TEXT, normalized_pain_points TEXT, normalized_use_cases TEXT, normalized_themes TEXT, normalized_tone TEXT, normalized_geo TEXT, normalized_topics TEXT);

CREATE TABLE entity_embeddings (
            embedding_id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT CHECK(entity_type IN ('creator', 'brand')),
            entity_id INTEGER,
            variant TEXT,
            embedding_vector TEXT,
            confidence REAL,
            source_text TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        , source_normalized_id INTEGER, vector_type TEXT, model_name TEXT);

CREATE TABLE entity_normalized (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id INTEGER NOT NULL,
            version TEXT DEFAULT 'v1',
            normalized_block TEXT NOT NULL,
            norm_fields TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

CREATE TABLE normalization_lexicon (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            raw_label TEXT,
            normalized_label TEXT,
            label_type TEXT,
            notes TEXT
        );

CREATE TABLE podcastindex_feeds (
            id INTEGER PRIMARY KEY,
            url TEXT,
            title TEXT,
            lastUpdate INTEGER,
            link TEXT,
            lastHttpStatus INTEGER,
            dead INTEGER,
            contentType TEXT,
            itunesId INTEGER,
            originalUrl TEXT,
            itunesAuthor TEXT,
            itunesOwnerName TEXT,
            explicit INTEGER,
            imageUrl TEXT,
            itunesType TEXT,
            generator TEXT,
            newestItemPubdate INTEGER,
            language TEXT,
            oldestItemPubdate INTEGER,
            episodeCount INTEGER,
            popularityScore INTEGER,
            priority INTEGER,
            createdOn INTEGER,
            updateFrequency INTEGER,
            chash TEXT,
            host TEXT,
            newestEnclosureUrl TEXT,
            podcastGuid TEXT,
            description TEXT,
            category1 TEXT,
            category2 TEXT,
            category3 TEXT,
            category4 TEXT,
            category5 TEXT,
            category6 TEXT,
            category7 TEXT,
            category8 TEXT,
            category9 TEXT,
            category10 TEXT,
            newestEnclosureDuration INTEGER
        );

CREATE TABLE podscan (
            id TEXT PRIMARY KEY,
            guid TEXT,
            podcastindex_id INTEGER,
            itunesid INTEGER,
            email TEXT,
            website TEXT,
            full_json TEXT,
            region TEXT
        );

CREATE TABLE socials (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            creator_adlid INTEGER NOT NULL,
            platform TEXT,
            handle TEXT,
            reach INTEGER,
            last_post TEXT,
            status INTEGER DEFAULT 100,
            source_url TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (creator_adlid) REFERENCES creators(adlid)
        );

CREATE TABLE sqlite_sequence(name,seq);

CREATE TABLE survey_responses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            creator_survey_id INTEGER NOT NULL,
            adlid INTEGER,
            source TEXT,
            sender_email TEXT,
            received_at TEXT,
            subject TEXT,
            message_id TEXT,
            in_reply_to TEXT,
            raw_eml_path TEXT,
            raw_body TEXT,
            parsed_fields_json TEXT,
            qa_json TEXT,
            model_name TEXT,
            prompt_version TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

CREATE TABLE survey_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
