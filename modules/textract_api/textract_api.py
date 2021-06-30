import json
import boto3


class OpticalCharacterReader:

    def __init__(self):
        self.textract_client = boto3.client('textract')

    def detect_document_text(self, filename: str):
        return self.textract_client.detect_document_text(
            Document={'S3Object': {
                # bucket name templated by Terraform
                'Bucket': '${bucket_name}',
                'Name': filename
            }}
        )

    @staticmethod
    def _filter_duplicate_textract_content_blocks(textract_blocks):
        """Remove duplicate text entries."""

        line_blocks = [block for block in textract_blocks
                       if block['BlockType'] == 'LINE']

        line_child_ids = []

        for block in line_blocks:
            for relationship in block['Relationships']:
                if relationship['Type'] == 'CHILD':
                    line_child_ids += relationship['Ids']

        unique_word_blocks = [block['Text'] for block in textract_blocks
                              if block['BlockType'] == 'WORD' and block['Id'] not in line_child_ids]

        return line_blocks + unique_word_blocks

    @classmethod
    def _refine_textract_api_response(cls, textract_api_response):
        """Remove textract API response specifics and duplicate text entries."""

        textract_blocks = [block for block in textract_api_response['Blocks']]

        unique_content_blocks = cls._filter_duplicate_textract_content_blocks(
            textract_blocks=textract_blocks)

        text_blocks = [
            {
                'Text': block['Text'],
                'Geometry': block['Geometry']
            }
            for block in unique_content_blocks
        ]

        return text_blocks

    @staticmethod
    def _simplify_ocr_boxes(ocr_boxes):
        """Enrich data in OCR boxes to make processing them more straightforward."""

        # X and Y coordinates are expressed as fractions of the canvas.
        # The origin is located top-left.
        # Some properties are commented out, because those are unused at the moment.
        text_boxes = [{
            'Text': box['Text'].strip(),
            'Top': box['Geometry']['BoundingBox']['Top'],
            'Left': box['Geometry']['BoundingBox']['Left'],
            # 'Height': box['Geometry']['BoundingBox']['Height'],
            # 'Width': box['Geometry']['BoundingBox']['Width'],
            'Bottom': box['Geometry']['BoundingBox']['Top'] + box['Geometry']['BoundingBox']['Height'],
            # 'Right': box['Geometry']['BoundingBox']['Left'] + box['Geometry']['BoundingBox']['Width'],
            'CenterY': box['Geometry']['BoundingBox']['Top'] + box['Geometry']['BoundingBox']['Height'] / 2,
            # 'CenterX': box['Geometry']['BoundingBox']['Left'] + box['Geometry']['BoundingBox']['Width'] / 2
        }
            for box in ocr_boxes]

        return text_boxes

    @classmethod
    def _construct_horizontal_lines(cls, ocr_boxes):
        """Join text boxes together based on the assumption that they form only horizontal(-ish) lines of text.

        Args:
            ocr_boxes (List of text boxes): List of dicts which contain text and detailed geometry information

        Returns:
            List of string: List of strings that make up horizontal lines of text
        """

        # Simplify input for code readability.
        text_boxes = cls._simplify_ocr_boxes(ocr_boxes=ocr_boxes)

        # Sort text boxes vertically.
        text_boxes.sort(key=lambda box: box['Top'])

        # Partition and horizontally sort boxes into lines.
        ordered_lines_of_boxes = []
        current_line_of_boxes = [text_boxes[0]]

        for box in text_boxes[1:]:
            # If the center of current box looked at fits in bounding area of the last box in the current line and vice versa,
            # then the current box probably belongs to the same line of text.
            # This assumes that text boxes belonging to the same line are largely horizontally aligned already.
            if current_line_of_boxes[-1]['Top'] < box['CenterY'] < current_line_of_boxes[-1]['Bottom'] \
                    and box['Top'] < current_line_of_boxes[-1]['CenterY'] < box['Bottom']:
                current_line_of_boxes.append(box)
            else:
                current_line_of_boxes.sort(key=lambda box: box['Left'])
                ordered_lines_of_boxes.append(current_line_of_boxes)
                current_line_of_boxes = [box]

        ordered_lines_of_boxes.append(current_line_of_boxes)

        # Create a string from boxes on a horizontal line.
        text_lines = [
            ' '.join([box['Text'] for box in line_of_boxes])
            for line_of_boxes in ordered_lines_of_boxes
        ]

        return text_lines

    @classmethod
    def extract_text_from_bullet_list(cls, bulleted_lines):
        """If present, remove bullet marks from a list of strings."""

        lower_first_chars = ''.join(
            [line[0].lower() for line in bulleted_lines])
        second_chars = ''.join(
            [line[1] for line in bulleted_lines])

        # If all text lines start with a non-alphanumeric character OR
        # all text lines start with the same character AND those are separated from the rest by a white space...
        if not any([char.isalnum() for char in lower_first_chars]) or \
                lower_first_chars == len(lower_first_chars) * lower_first_chars[0] and second_chars.isspace():
            # ...then those characters are probably just bullets and should be removed.
            return [line[1:].lstrip() for line in bulleted_lines]
        else:
            return bulleted_lines

    @classmethod
    def _refine_to_horizontal_text_lines(cls, textract_api_response):
        """Refine a Textract API response to horizontal lines of text."""

        # Defining a method like this may seem overkill,
        # but it makes unit testing far more straightforward.
        refined_response = cls._refine_textract_api_response(
            textract_api_response=textract_api_response)

        text_lines = cls._construct_horizontal_lines(
            ocr_boxes=refined_response)

        return cls.extract_text_from_bullet_list(bulleted_lines=text_lines)

    def get_horizontal_text_lines(self, filename: str):
        """Get horizontal lines of text form an image.

        Args:
            filename (str): The key of a file in S3.

        Returns:
            List of string: List of detected lines of text
        """

        response = self.detect_document_text(filename=filename)

        return self._refine_to_horizontal_text_lines(textract_api_response=response)


def lambda_handler(event, context):
    print(event)

    event_body = json.loads(event['body'])

    optical_character_reader = OpticalCharacterReader()
    text_lines = optical_character_reader.get_horizontal_text_lines(
        filename=event_body['name'])

    print(text_lines)

    return text_lines
