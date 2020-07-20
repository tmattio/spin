CREATE TABLE "public"."users"(
  "id" serial NOT NULL,
  "user_id" int NOT NULL,
  "name" text CONSTRAINT "name_length" CHECK (char_length("name") <= 60),
  "created_at" timestamp(0) without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp(0) without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "users_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "public"."users" ("id") MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION "public"."set_current_timestamp_updated_at"()
RETURNS TRIGGER AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = now();
  RETURN _new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "set_public_users_updated_at"
BEFORE UPDATE ON "public"."users"
FOR EACH ROW
EXECUTE PROCEDURE "public"."set_current_timestamp_updated_at"();

COMMENT ON TRIGGER "set_public_users_updated_at" ON "public"."users" 
IS 'trigger to set value of column "updated_at" to current timestamp on row update';
