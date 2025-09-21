import os
import base64
import requests

class ImageToEmoji:
    """
    A class to interact with the OpenAI API to convert images into a string of emojis.
    ### How to Use:
    ~~~~~~~~~~~~~~~~~~
    Auto detect:
        >>> model = ImageToEmoji()
        >>> response = model.send_image(image) 
        # image can be eiher a file path, URL, or base64 encoded string.
        
    Base64 encoded image:
        >>> model = ImageToEmoji()
        >>> response = model.send_image(image_b64, type='base64')
        # image_b64 is a base64 encoded string of the image.
        
    Image file path:
        >>> model = ImageToEmoji()
        >>> response = model.send_image(/path/to/image, type='path')
        
    Image URL:
        >>> model = ImageToEmoji()
        >>> response = model.send_image("http://example.com/image.jpg", type='url')
        
    response is a string of emojis.
    ~~~~~~~~~~~~~~~~~~
    ### Constructor
    #### api_key
    You can set the API key by passing it to the constructor, if not provided, it will look for the `OPENAI_API_KEY` environment variable.
    #### model
    The default model is `gpt-4.1-nano`, but you can specify a different model if needed.
    """
    
    def __init__(self, api_key: str=None, model: str="gpt-4.1-nano", prompt_path: str=None):
        if not api_key:
            self._api_key = os.getenv("OPENAI_API_KEY")
        else:
            self._api_key = api_key
            
        self._model = model
        if prompt_path is not None:
            with open(prompt_path, 'r') as file:
                self._system_prompt = file.read()
        else:
            self._system_prompt = ''
            
        

    def send_image(self, image: str, type=None, prompt=''):
        """
        Send an image to the OpenAI API and get a response.
        Args:
            image (str or bytes): The image to send, can be a file path, URL, or base64 encoded string.
            type (str, optional): The type of the image ('base64', 'path', or 'url'). If None, it will be inferred.
        Returns:
            str: The response from the OpenAI API, which should be a string of emojis.
        """
        if not self._api_key:
            raise ValueError("API key is not set. Please set the OPENAI_API_KEY environment variable.")
        
        def _is_base64(s: str):
            try:
                if not isinstance(s, str) or len(s) % 4 != 0:
                    return False
                base64.b64decode(s, validate=True)
                return True
            except Exception:
                return False

        if type is None:
            if isinstance(image, str):
                if image.startswith("data:image/") and ";base64," in image:
                    type = 'base64'
                elif os.path.isfile(image):
                    type = 'path'
                elif image.startswith("http://") or image.startswith("https://"):
                    type = 'url'
                elif _is_base64(image):
                    type = 'base64'
                else:
                    raise ValueError("Cannot detect image type. Provide a valid type ('base64', 'path', or 'url').")
            elif isinstance(image, bytes):
                type = 'base64'
            else:
                raise ValueError("Unsupported image format. Provide a valid type ('base64', 'path', or 'url').")
        match type:
            case 'base64':
                if image.startswith("data:image/") and ";base64," in image:
                    image_b64 = image.split(",")[1]
                else:
                    image_b64 = image
            case 'path':
                if not os.path.isfile(image):
                    raise ValueError("File does not exist.")
                image_b64 = self.image_to_base64(image)
            case 'url':
                image_b64 = self._fetch_image_from_url(image)
            case _:
                raise ValueError("Unsupported image type.")
        
        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json"
        }
        data = {
            "model": self._model,
            "messages": [
                {
                    "role": "system",
                    "content": "Describe this image."
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{image_b64}"
                            }
                        }
                    ]
                }
            ],
            "max_tokens": 1000
        }
        
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        
        data = {
            "model": self._model,
            "messages": [
                {
                    "role": "system",
                    "content": "Output 10 different emoji based on the following instructions, don't output others texts, just emoji."
                },
                {
                    "role": "user",
                    "content": response.json()['choices'][0]['message']['content']
                }
            ],
            "max_tokens": 100
        }
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    
    def image_to_base64(self, image_path: str):
        """Convert an image file to a base64 encoded string."""
        with open(image_path, "rb") as img_file:
            return base64.b64encode(img_file.read()).decode('utf-8')
        
    def _fetch_image_from_url(self, image_url: str):
        """Fetch an image from a URL and convert it to base64."""
        response = requests.get(image_url)
        if response.status_code != 200:
            raise ValueError("Failed to fetch image from URL.")
        return base64.b64encode(response.content).decode('utf-8')

