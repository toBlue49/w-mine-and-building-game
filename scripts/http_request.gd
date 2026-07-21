extends HTTPRequest

var data_array: Array[Dictionary]
var file_request_finished = false
var request_finished = false
var request_counter = 0

func curl_url(url: String):
	request_finished = false
	request_data(url)
	
	while request_finished == false:
		await get_tree().process_frame
	
	var result = data_array[request_counter]
	data_array[request_counter] = {}
	request_counter += 1
	return result

func request_data(url: String):
	set_tls_options(TLSOptions.client_unsafe())
	request_completed.connect(_on_request_completed)
	
	if !url.begins_with("http"):
		url = "http://" + url
	
	request(url)
	
func _on_request_completed(result, response_code, headers, body):
	print_rich("[color=purple][HTTP] Request Data: [color=#BBB]result=[color=purple]%s[color=#BBB]; response_code=[color=purple]%s[color=#BBB]; headers=[color=purple]%s[color=#BBB];" %[result, response_code, headers])
	set_download_file("")
	
	data_array.insert(request_counter, {"response_code": response_code, "body": body})
	request_finished = true

func download_file_to_path(url: String, filepath: String):
	file_request_finished = false
	print_rich("[b]Downloading file [/b][color=#88FF88]%s[/color] to [color=#88FF88]%s[/color]" %[url, filepath])
	set_download_file(filepath)
	request_completed.connect(_on_file_request_completed)
	request(url)
	while !file_request_finished:
		await get_tree().create_timer(0.1).timeout
	print_rich("[color=#8F8]Finished downloading file!")
	return

func _on_file_request_completed(_result, _response_code, _headers, _body):
	file_request_finished = true
	request_completed.disconnect(_on_file_request_completed)
