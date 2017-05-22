# Copyright 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START app]
import logging

# [START imports]
from flask import Flask, render_template, request, jsonify, current_app
import json
from functools import wraps
from google.cloud import datastore



# [END imports]

# [START create_app]
app = Flask(__name__)
# [END create_app]

builtin_list = list

def support_jsonp(f):
    """Wraps JSONified output for JSONP"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        callback = request.args.get('callback', False)
        if callback:
            content = str(callback) + '(' + str(f(*args,**kwargs).data) + ')'
            return current_app.response_class(content, mimetype='application/javascript')
        else:
            return f(*args, **kwargs)
    return decorated_function

def from_datastore(entity):
    """Translates Datastore results into the format expected by the
    application.
    Datastore typically returns:
        [Entity{key: (kind, id), prop: val, ...}]
    This returns:
        {id: id, prop: val, ...}
    """
    if not entity:
        return None
    if isinstance(entity, builtin_list):
        entity = entity.pop()

    entity['id'] = entity.key.id
    return entity

# [START form]
@app.route('/products/autocomplete')
@support_jsonp

def form():
    callback = request.args.get('callback')
    phrase = request.args.get('phrase')

    ds = datastore.Client(project="YOUR_PROJECT_ID")

    query = ds.query(
            kind='Product',
            filters=[
                ('downcase_name', '>=', phrase),
                ('downcase_name', '<', phrase + u'\ufffd')
            ]
    )

    query_iterator = query.fetch(limit=5, start_cursor=None)
    page = next(query_iterator.pages)

    entities = builtin_list(map(from_datastore, page))


    #entities = builtin_list[map(from_datastore, page)]
    #entities = []

    # for entity in page:
    #     record = from_datastore(entity)
    #     #entities.append(record)
    #     print record


    #print entities

    # next_cursor = (
    #     query_iterator.next_page_token.decode('utf-8')
    #     if query_iterator.next_page_token else None)


    #return render_template('form.html')
    #return entities

    # return render_template(
    #         'jsonp.html',
    #         mydata=entities,
    #         callback=callback)


    return jsonify(entities)

    # [END render_template]

# [END form]


# [START submitted]
@app.route('/submitted', methods=['POST'])
def submitted_form():
    name = request.form['name']
    email = request.form['email']
    site = request.form['site_url']
    comments = request.form['comments']

    # [END submitted]
    # [START render_template]

    return render_template(
        'submitted_form.html',
        name=name,
        email=email,
        site=site,
        comments=comments)
    # [END render_template]


@app.errorhandler(500)
def server_error(e):
    # Log the error and stacktrace.
    logging.exception('An error occurred during a request.')
    return 'An internal error occurred.', 500
# [END app]
