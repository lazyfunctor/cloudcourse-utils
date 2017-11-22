import http from "k6/http";
import { sleep } from "k6";

export default function() {
  var url = "http://demo-1761846787.us-east-1.elb.amazonaws.com/event/";
  var payload = JSON.stringify({ data: "test string"});
  var params =  { headers: { "Content-Type": "application/json" } }
  http.post(url, payload, params);
  sleep(1);
};